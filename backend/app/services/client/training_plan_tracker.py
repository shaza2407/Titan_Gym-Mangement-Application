"""
app/services/training_plan_tracker.py
Tracks training plan completion for achievements
"""
import json
import logging
from datetime import date, datetime, timedelta
from typing import Dict, List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func, update
from sqlalchemy.orm import selectinload

from app.models.training_plan import TrainingPlan, PlanStatus
from app.models.training_plan import TrainingPlanTracking, WorkoutStatus, TrainingPlanWeekProgress, DayStatus
from app.models.client import Client
from app.services.coach.achievement_engine import achievement_engine

logger = logging.getLogger(__name__)


class TrainingPlanTracker:
    """Tracks daily workout completion and updates achievements"""

    async def mark_workout_completed(
            self,
            client_id: int,
            plan_id: int,
            tracking_date: date,
            completed_exercises: int,
            total_exercises: int,
            duration_minutes: int = None,
            db: AsyncSession = None
    ):
        """Mark a specific day's workout as completed"""

        # Calculate completion percentage
        completion = (completed_exercises / total_exercises * 100) if total_exercises > 0 else 0

        # Get or create tracking record
        result = await db.execute(
            select(TrainingPlanTracking)
            .where(
                and_(
                    TrainingPlanTracking.clientID == client_id,
                    TrainingPlanTracking.planID == plan_id,
                    TrainingPlanTracking.tracking_date == tracking_date
                )
            )
        )
        tracking = result.scalar_one_or_none()

        if not tracking:
            # Need to determine week and day number
            plan = await db.execute(
                select(TrainingPlan).where(TrainingPlan.planID == plan_id)
            )
            plan = plan.scalar_one()

            # Parse plan JSON to get week structure
            plan_data = json.loads(plan.plan_json)
            week_num, day_num = self._calculate_week_and_day(plan_data, tracking_date, plan.created_at.date())

            tracking = TrainingPlanTracking(
                clientID=client_id,
                planID=plan_id,
                tracking_date=tracking_date,
                week_number=week_num,
                day_number=day_num,
                planned_exercises=total_exercises,
                completed_exercises=completed_exercises,
                completion_percentage=completion,
                status=WorkoutStatus.COMPLETED if completion >= 80 else WorkoutStatus.PARTIAL,
                duration_minutes=duration_minutes,
                completed_at=datetime.now()
            )
            db.add(tracking)
        else:
            tracking.completed_exercises = completed_exercises
            tracking.completion_percentage = completion
            tracking.status = WorkoutStatus.COMPLETED if completion >= 80 else WorkoutStatus.PARTIAL
            tracking.duration_minutes = duration_minutes
            tracking.completed_at = datetime.now()

        await db.commit()

        # Check if plan is now complete
        await self._check_plan_completion(client_id, plan_id, db)

        # Update achievements
        await achievement_engine.update_goal_crusher(client_id, db)
        await achievement_engine.update_master_trainer(client_id, db)

        # Update weekly progress
        await self._update_weekly_progress(client_id, plan_id, db)

        return tracking

    async def _check_plan_completion(self, client_id: int, plan_id: int, db: AsyncSession):
        """Check if all workouts in plan are completed"""

        # Get plan details
        result = await db.execute(
            select(TrainingPlan).where(TrainingPlan.planID == plan_id)
        )
        plan = result.scalar_one()

        # Parse plan to get total expected workouts
        plan_data = json.loads(plan.plan_json)
        total_expected_workouts = self._count_total_workouts(plan_data)

        # Count completed workouts
        result = await db.execute(
            select(func.count(TrainingPlanTracking.trackingID))
            .where(
                and_(
                    TrainingPlanTracking.clientID == client_id,
                    TrainingPlanTracking.planID == plan_id,
                    TrainingPlanTracking.status == WorkoutStatus.COMPLETED
                )
            )
        )
        completed_workouts = result.scalar() or 0

        # Mark plan as completed if all workouts done
        if completed_workouts >= total_expected_workouts and plan.status != PlanStatus.COMPLETED:
            plan.status = PlanStatus.COMPLETED
            plan.completed_at = datetime.now()
            await db.commit()
            logger.info(f"🎉 Client {client_id} completed training plan {plan_id}!")

            # Trigger achievement updates
            await achievement_engine.update_goal_crusher(client_id, db)

    async def _update_weekly_progress(self, client_id: int, plan_id: int, db: AsyncSession):
        """Aggregate weekly progress"""

        # Get all tracking for this plan
        result = await db.execute(
            select(TrainingPlanTracking)
            .where(
                and_(
                    TrainingPlanTracking.clientID == client_id,
                    TrainingPlanTracking.planID == plan_id
                )
            )
        )
        trackings = result.scalars().all()

        # Group by week
        weeks = {}
        for tracking in trackings:
            if tracking.week_number not in weeks:
                weeks[tracking.week_number] = []
            weeks[tracking.week_number].append(tracking)

        # Update or create week progress
        for week_num, week_trackings in weeks.items():
            completed = sum(1 for t in week_trackings if t.status == WorkoutStatus.COMPLETED)
            skipped = sum(1 for t in week_trackings if t.status == WorkoutStatus.SKIPPED)
            total = len(week_trackings)

            week_start = min(t.tracking_date for t in week_trackings)
            week_end = max(t.tracking_date for t in week_trackings)

            result = await db.execute(
                select(TrainingPlanWeekProgress)
                .where(
                    and_(
                        TrainingPlanWeekProgress.clientID == client_id,
                        TrainingPlanWeekProgress.planID == plan_id,
                        TrainingPlanWeekProgress.week_number == week_num
                    )
                )
            )
            week_progress = result.scalar_one_or_none()

            if not week_progress:
                week_progress = TrainingPlanWeekProgress(
                    clientID=client_id,
                    planID=plan_id,
                    week_number=week_num,
                    week_start_date=week_start,
                    week_end_date=week_end
                )
                db.add(week_progress)

            week_progress.total_days = total
            week_progress.completed_days = completed
            week_progress.skipped_days = skipped
            week_progress.average_completion = (completed / total * 100) if total > 0 else 0
            week_progress.week_status = DayStatus.COMPLETED if completed == total else DayStatus.IN_PROGRESS

        await db.commit()

    def _calculate_week_and_day(self, plan_data: dict, tracking_date: date, plan_start_date: date) -> tuple:
        """Calculate week and day number based on plan structure"""
        days_since_start = (tracking_date - plan_start_date).days
        week_num = (days_since_start // 7) + 1
        day_num = (days_since_start % 7) + 1
        return week_num, day_num

    def _count_total_workouts(self, plan_data: dict) -> int:
        """Count total number of workouts in plan"""
        total = 0
        for week in plan_data.get("plan", []):
            total += len(week.get("days", []))
        return total

    async def get_plan_progress(self, client_id: int, plan_id: int, db: AsyncSession) -> Dict:
        """Get detailed progress for a training plan"""

        # Get plan
        result = await db.execute(
            select(TrainingPlan).where(TrainingPlan.planID == plan_id)
        )
        plan = result.scalar_one()

        # Get tracking data
        result = await db.execute(
            select(TrainingPlanTracking)
            .where(
                and_(
                    TrainingPlanTracking.clientID == client_id,
                    TrainingPlanTracking.planID == plan_id
                )
            )
            .order_by(TrainingPlanTracking.tracking_date)
        )
        trackings = result.scalars().all()

        # Calculate stats
        total_workouts = len(trackings)
        completed_workouts = sum(1 for t in trackings if t.status == WorkoutStatus.COMPLETED)
        partial_workouts = sum(1 for t in trackings if t.status == WorkoutStatus.PARTIAL)
        skipped_workouts = sum(1 for t in trackings if t.status == WorkoutStatus.SKIPPED)

        # Get weekly progress
        result = await db.execute(
            select(TrainingPlanWeekProgress)
            .where(
                and_(
                    TrainingPlanWeekProgress.clientID == client_id,
                    TrainingPlanWeekProgress.planID == plan_id
                )
            )
            .order_by(TrainingPlanWeekProgress.week_number)
        )
        weeks = result.scalars().all()

        return {
            "plan_id": plan_id,
            "plan_title": plan.title,
            "status": plan.status,
            "total_workouts": total_workouts,
            "completed_workouts": completed_workouts,
            "partial_workouts": partial_workouts,
            "skipped_workouts": skipped_workouts,
            "completion_percentage": (completed_workouts / total_workouts * 100) if total_workouts > 0 else 0,
            "weeks": [
                {
                    "week_number": w.week_number,
                    "completed_days": w.completed_days,
                    "total_days": w.total_days,
                    "percentage": (w.completed_days / w.total_days * 100) if w.total_days > 0 else 0,
                    "status": w.week_status
                }
                for w in weeks
            ],
            "daily_tracking": [
                {
                    "date": t.tracking_date,
                    "completion": t.completion_percentage,
                    "status": t.status,
                    "exercises_completed": f"{t.completed_exercises}/{t.planned_exercises}"
                }
                for t in trackings
            ]
        }


training_plan_tracker = TrainingPlanTracker()