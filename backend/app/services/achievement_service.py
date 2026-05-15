"""
app/services/achievement_service.py
────────────────────────────────────
Central Achievement Evaluation Engine.

Usage (called after every trigger event):
    engine = AchievementEngine(db)
    new_badges = await engine.evaluate_user(user_id)

Trigger events:
  • User checks in        → evaluate CHECKIN, STREAK, WEEKLY, MONTHLY, EARLY_BIRD
  • User joins a class    → evaluate CLASS
  • User finishes a plan  → evaluate TRAINING_PLAN

All badge-unlock logic lives here — never in routes.
"""

import logging
from datetime import datetime, timezone
from typing import List

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.models.achievement import (
    Achievement, AchievementType, UserAchievement, UserCheckin
)
from app.models.training_plan import TrainingPlan
from app.services.streak_service import (
    calculate_streak,
    count_weekly_checkins,
    count_monthly_checkins,
    count_early_bird_checkins,
)

logger = logging.getLogger(__name__)


class AchievementEngine:
    def __init__(self, db: AsyncSession):
        self.db = db

    # ── Public entry points ───────────────────────────────────────────────────

    async def evaluate_checkin(self, user_id: int) -> List[Achievement]:
        """Call after a new check-in is saved."""
        return await self._evaluate_user(
            user_id,
            types=[
                AchievementType.CHECKIN,
                AchievementType.STREAK,
                AchievementType.WEEKLY,
                AchievementType.MONTHLY,
                AchievementType.EARLY_BIRD,
            ],
        )

    async def evaluate_class_joined(self, user_id: int) -> List[Achievement]:
        """Call after user joins / completes a class."""
        return await self._evaluate_user(user_id, types=[AchievementType.CLASS])

    async def evaluate_plan_completed(self, user_id: int) -> List[Achievement]:
        """Call after user completes a training plan."""
        return await self._evaluate_user(user_id, types=[AchievementType.TRAINING_PLAN])

    # ── Core engine ───────────────────────────────────────────────────────────

    async def _evaluate_user(
        self, user_id: int, types: List[AchievementType]
    ) -> List[Achievement]:
        """
        Recalculate progress for the given achievement types.
        Unlock any that are newly completed.
        Returns the list of newly unlocked Achievement objects.
        """
        # 1. Fetch all active achievements of the relevant types
        result = await self.db.execute(
            select(Achievement).where(
                Achievement.is_active == True,
                Achievement.achievement_type.in_(types),
            )
        )
        achievements = result.scalars().all()
        if not achievements:
            return []

        # 2. Pre-fetch user context (check-ins, plans, etc.)
        context = await self._build_context(user_id, types)

        newly_unlocked: List[Achievement] = []

        for ach in achievements:
            progress = self._compute_progress(ach, context)
            ua = await self._get_or_create_ua(user_id, ach.achievement_id)

            if ua.is_completed:
                continue  # already earned — skip

            ua.progress_value = progress

            if progress >= ach.target_value:
                ua.is_completed = True
                ua.completed_at = datetime.now(timezone.utc)
                newly_unlocked.append(ach)
                logger.info(
                    "🏅 User %s unlocked badge '%s'", user_id, ach.title
                )

        await self.db.commit()
        return newly_unlocked

    # ── Progress calculators ──────────────────────────────────────────────────

    def _compute_progress(self, ach: Achievement, ctx: dict) -> int:
        t = ach.achievement_type

        if t == AchievementType.CHECKIN:
            return ctx["total_checkins"]

        elif t == AchievementType.STREAK:
            return ctx["current_streak"]

        elif t == AchievementType.WEEKLY:
            return ctx["weekly_checkins"]

        elif t == AchievementType.MONTHLY:
            return ctx["monthly_checkins"]

        elif t == AchievementType.EARLY_BIRD:
            return ctx["early_bird_count"]

        elif t == AchievementType.CLASS:
            return ctx["class_count"]

        elif t == AchievementType.TRAINING_PLAN:
            return ctx["plans_completed"]

        return 0

    # ── DB helpers ────────────────────────────────────────────────────────────

    async def _build_context(self, user_id: int, types: List[AchievementType]) -> dict:
        """Fetch all user statistics needed for the requested achievement types."""
        ctx: dict = {}

        needs_checkins = bool(
            {
                AchievementType.CHECKIN,
                AchievementType.STREAK,
                AchievementType.WEEKLY,
                AchievementType.MONTHLY,
                AchievementType.EARLY_BIRD,
            }
            & set(types)
        )

        if needs_checkins:
            result = await self.db.execute(
                select(UserCheckin).where(UserCheckin.userID == user_id)
                .order_by(UserCheckin.checkin_date)
            )
            checkins = result.scalars().all()
            dates         = [c.checkin_date for c in checkins]
            datetimes     = [c.checkin_time for c in checkins if c.checkin_time]

            ctx["total_checkins"]   = len(dates)
            ctx["current_streak"]   = calculate_streak(dates)
            ctx["weekly_checkins"]  = count_weekly_checkins(dates)
            ctx["monthly_checkins"] = count_monthly_checkins(dates)
            ctx["early_bird_count"] = count_early_bird_checkins(datetimes)

        if AchievementType.CLASS in types:
            # Count completed group classes (status = 'completed')
            # Assumes a user_classes table exists; adapt join/model as needed
            from sqlalchemy import text
            r = await self.db.execute(
                text(
                    "SELECT COUNT(*) FROM user_classes "
                    "WHERE \"userID\" = :uid AND status = 'completed'"
                ),
                {"uid": user_id},
            )
            ctx["class_count"] = r.scalar() or 0

        if AchievementType.TRAINING_PLAN in types:
            r = await self.db.execute(
                select(func.count()).select_from(TrainingPlan)
                # Mark plan as "completed" by having a non-null completed_at;
                # adjust if your model uses a boolean flag instead.
                .where(TrainingPlan.clientID == user_id)
            )
            ctx["plans_completed"] = r.scalar() or 0

        return ctx

    async def _get_or_create_ua(
        self, user_id: int, achievement_id: int
    ) -> UserAchievement:
        result = await self.db.execute(
            select(UserAchievement).where(
                UserAchievement.userID         == user_id,
                UserAchievement.achievement_id == achievement_id,
            )
        )
        ua = result.scalar_one_or_none()
        if not ua:
            ua = UserAchievement(
                userID=user_id,
                achievement_id=achievement_id,
                progress_value=0,
                is_completed=False,
            )
            self.db.add(ua)
            await self.db.flush()
        return ua