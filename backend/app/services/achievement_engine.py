"""
app/services/achievement_engine.py
Centralized service that tracks and updates all achievements in real-time.
"""
import logging
from datetime import date, datetime, timedelta
from typing import Dict, List, Optional, Set
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func, distinct, case
from sqlalchemy.orm import selectinload

from app.models.achievement import Achievement
from app.models.client_achievement import ClientAchievement
from app.models.check_in import CheckIn
from app.models.client_class_enrollment import ClientClassEnrollment
from app.models.class_session import ClassSession
from app.models.training_plan import TrainingPlan
from app.models.client import Client

logger = logging.getLogger(__name__)


class AchievementEngine:
    """Handles all achievement progress calculations and updates"""

    async def update_all_achievements(self, client_id: int, db: AsyncSession):
        """Update all achievements for a specific client"""
        await self.update_monthly_champion(client_id, db)
        await self.update_class_enthusiast(client_id, db)
        await self.update_early_bird(client_id, db)
        await self.update_consistency_king(client_id, db)
        await self.update_social_butterfly(client_id, db)
        await self.update_goal_crusher(client_id, db)

        # New achievements
        await self.update_night_owl(client_id, db)
        await self.update_weekend_warrior(client_id, db)
        await self.update_perfect_week(client_id, db)
        await self.update_master_trainer(client_id, db)
        await self.update_gym_rat(client_id, db)
        await self.update_explorer(client_id, db)
        await self.update_dedication(client_id, db)
        await self.update_super_streak(client_id, db)

        await db.commit()

    # ============ EXISTING ACHIEVEMENTS ============

    async def update_monthly_champion(self, client_id: int, db: AsyncSession):
        """Check in 20 times in a month"""
        current_month = date.today().month
        current_year = date.today().year

        result = await db.execute(
            select(func.count(CheckIn.checkInID))
            .where(
                and_(
                    CheckIn.clientID == client_id,
                    func.extract('month', CheckIn.checked_in_at) == current_month,
                    func.extract('year', CheckIn.checked_in_at) == current_year
                )
            )
        )
        count = result.scalar() or 0
        await self._update_progress(client_id, "monthly_champion", count, db)

    async def update_class_enthusiast(self, client_id: int, db: AsyncSession):
        """Attend 10 different classes"""
        result = await db.execute(
            select(func.count(distinct(ClassSession.title)))
            .join(ClientClassEnrollment, ClientClassEnrollment.sessionID == ClassSession.id)
            .where(ClientClassEnrollment.clientID == client_id)
        )
        count = result.scalar() or 0
        await self._update_progress(client_id, "class_enthusiast", count, db)

    async def update_early_bird(self, client_id: int, db: AsyncSession):
        """Check in before 7 AM ten times"""
        result = await db.execute(
            select(func.count(CheckIn.checkInID))
            .where(
                and_(
                    CheckIn.clientID == client_id,
                    CheckIn.check_in_hour < 7
                )
            )
        )
        count = result.scalar() or 0
        await self._update_progress(client_id, "early_bird", count, db)

    async def update_consistency_king(self, client_id: int, db: AsyncSession):
        """Maintain a 30-day check-in streak"""
        streak = await self._calculate_longest_streak(client_id, db)
        await self._update_progress(client_id, "consistency_king", streak, db)

    async def update_social_butterfly(self, client_id: int, db: AsyncSession):
        """Participate in 5 group classes"""
        result = await db.execute(
            select(func.count(ClientClassEnrollment.enrollmentID))
            .where(
                and_(
                    ClientClassEnrollment.clientID == client_id,
                    ClientClassEnrollment.is_group_class == 1
                )
            )
        )
        count = result.scalar() or 0
        await self._update_progress(client_id, "social_butterfly", count, db)

    async def update_goal_crusher(self, client_id: int, db: AsyncSession):
        """Complete 3 training plans"""
        result = await db.execute(
            select(func.count(TrainingPlan.planID))
            .where(
                and_(
                    TrainingPlan.clientID == client_id,
                    TrainingPlan.status == "completed"
                )
            )
        )
        count = result.scalar() or 0
        await self._update_progress(client_id, "goal_crusher", count, db)

    # ============ NEW ACHIEVEMENTS ============

    async def update_night_owl(self, client_id: int, db: AsyncSession):
        """Check in after 8 PM ten times"""
        result = await db.execute(
            select(func.count(CheckIn.checkInID))
            .where(
                and_(
                    CheckIn.clientID == client_id,
                    CheckIn.check_in_hour >= 20  # 8 PM or later
                )
            )
        )
        count = result.scalar() or 0
        await self._update_progress(client_id, "night_owl", count, db)

    async def update_weekend_warrior(self, client_id: int, db: AsyncSession):
        """Check in on weekends 15 times"""
        result = await db.execute(
            select(func.count(CheckIn.checkInID))
            .where(
                and_(
                    CheckIn.clientID == client_id,
                    # Saturday (6) or Sunday (7) in PostgreSQL/SQLite
                    func.strftime('%w', CheckIn.checked_in_at).in_(['6', '0'])
                )
            )
        )
        count = result.scalar() or 0
        await self._update_progress(client_id, "weekend_warrior", count, db)

    async def update_perfect_week(self, client_id: int, db: AsyncSession):
        """Check in 5 days in a single week"""
        # Group check-ins by week and count distinct days
        result = await db.execute(
            select(
                func.date_trunc('week', CheckIn.checked_in_at).label('week_start'),
                func.count(distinct(func.date(CheckIn.checked_in_at))).label('days_count')
            )
            .where(CheckIn.clientID == client_id)
            .group_by(func.date_trunc('week', CheckIn.checked_in_at))
            .having(func.count(distinct(func.date(CheckIn.checked_in_at))) >= 5)
        )
        perfect_weeks = len(result.all())
        await self._update_progress(client_id, "perfect_week", perfect_weeks, db)

    async def update_master_trainer(self, client_id: int, db: AsyncSession):
        """Complete 5 different training plans (different goals)"""
        result = await db.execute(
            select(func.count(distinct(TrainingPlan.goal)))
            .where(
                and_(
                    TrainingPlan.clientID == client_id,
                    TrainingPlan.status == "completed"
                )
            )
        )
        count = result.scalar() or 0
        await self._update_progress(client_id, "master_trainer", count, db)

    async def update_gym_rat(self, client_id: int, db: AsyncSession):
        """Total 100 check-ins overall"""
        result = await db.execute(
            select(func.count(CheckIn.checkInID))
            .where(CheckIn.clientID == client_id)
        )
        count = result.scalar() or 0
        await self._update_progress(client_id, "gym_rat", count, db)

    async def update_explorer(self, client_id: int, db: AsyncSession):
        """Visit 3 different gym locations"""
        result = await db.execute(
            select(func.count(distinct(CheckIn.gymID)))
            .where(CheckIn.clientID == client_id)
        )
        count = result.scalar() or 0
        await self._update_progress(client_id, "explorer", count, db)

    async def update_dedication(self, client_id: int, db: AsyncSession):
        """Complete a 90-day streak"""
        streak = await self._calculate_longest_streak(client_id, db)
        await self._update_progress(client_id, "dedication", streak, db)

    async def update_super_streak(self, client_id: int, db: AsyncSession):
        """Complete a 365-day streak (full year)"""
        streak = await self._calculate_longest_streak(client_id, db)
        await self._update_progress(client_id, "super_streak", streak, db)

    # ============ HELPER METHODS ============

    async def _calculate_longest_streak(self, client_id: int, db: AsyncSession) -> int:
        """Calculate the longest consecutive day check-in streak"""
        result = await db.execute(
            select(CheckIn.checked_in_at)
            .where(CheckIn.clientID == client_id)
            .order_by(CheckIn.checked_in_at)
            .distinct(func.date(CheckIn.checked_in_at))
        )

        dates = [row[0].date() for row in result.all()]

        if not dates:
            return 0

        longest_streak = 1
        current_streak = 1

        for i in range(1, len(dates)):
            if (dates[i] - dates[i - 1]).days == 1:
                current_streak += 1
                longest_streak = max(longest_streak, current_streak)
            else:
                current_streak = 1

        return longest_streak

    async def _update_progress(self, client_id: int, achievement_key: str, current_value: int, db: AsyncSession):
        """Update or create achievement progress record"""
        # Get achievement
        result = await db.execute(
            select(Achievement).where(Achievement.key == achievement_key)
        )
        achievement = result.scalar_one_or_none()

        if not achievement:
            logger.warning(f"Achievement {achievement_key} not found in database")
            return

        # Get or create client achievement
        result = await db.execute(
            select(ClientAchievement)
            .where(
                and_(
                    ClientAchievement.clientID == client_id,
                    ClientAchievement.achievementID == achievement.achievementID
                )
            )
        )
        client_achievement = result.scalar_one_or_none()

        if not client_achievement:
            client_achievement = ClientAchievement(
                clientID=client_id,
                achievementID=achievement.achievementID,
                current_value=0,
                is_unlocked=False
            )
            db.add(client_achievement)

        # Update progress
        client_achievement.current_value = min(current_value, achievement.target)

        # Check if newly unlocked
        was_unlocked = client_achievement.is_unlocked
        client_achievement.is_unlocked = current_value >= achievement.target

        if not was_unlocked and client_achievement.is_unlocked:
            client_achievement.unlocked_at = datetime.now()
            logger.info(f"🎉 Client {client_id} unlocked achievement: {achievement.name}!")

        client_achievement.updated_at = datetime.now()

    async def get_client_achievements(self, client_id: int, db: AsyncSession) -> List[dict]:
        """Get all achievements with progress for a client"""
        result = await db.execute(
            select(Achievement, ClientAchievement)
            .outerjoin(
                ClientAchievement,
                and_(
                    Achievement.achievementID == ClientAchievement.achievementID,
                    ClientAchievement.clientID == client_id
                )
            )
            .order_by(Achievement.target)
        )

        achievements = []
        for achievement, progress in result.all():
            achievements.append({
                "id": achievement.achievementID,
                "key": achievement.key,
                "name": achievement.name,
                "description": achievement.description,
                "icon": achievement.icon_emoji or "🏅",
                "target": achievement.target,
                "unit": achievement.unit,
                "current_value": progress.current_value if progress else 0,
                "is_unlocked": progress.is_unlocked if progress else False,
                "unlocked_at": progress.unlocked_at if progress else None,
                "progress_percentage": min(100,
                                           int((progress.current_value / achievement.target) * 100)) if progress else 0
            })

        return achievements


achievement_engine = AchievementEngine()