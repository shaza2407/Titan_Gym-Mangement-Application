"""
app/services/achievement_engine.py
────────────────────────────────────
Event-driven achievement engine with:
  • Sequential level unlocking (Bronze → Silver → Gold → Platinum → Diamond)
  • Progress carry-forward across levels
  • Badge Collector auto-recalculation
  • Only updates achievements relevant to the current event
"""

import logging
from datetime import date, datetime, timezone, timedelta
from typing import List, Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func, distinct

from app.models.achievement import Achievement, AchievementCategory
from app.models.attendance import Attendance
from app.models.client_achievement import ClientAchievement
from app.models.training_plan import TrainingPlan, PlanStatus
# from app.models.client_class_enrollment import ClientClassEnrollment // not do yet

logger = logging.getLogger(__name__)


class AchievementEngine:
    """
    Central service for achievement progress & unlock logic.

    Call the appropriate on_* method after each event — do NOT call
    update_all_achievements on every request (performance rule).
    """

    # ── Public event handlers ─────────────────────────────────────────────────

    async def on_checkin(self, client_id: int, db: AsyncSession) -> None:
        """Call after every successful check-in."""
        await self._update_gym_rat(client_id, db)
        await self._update_monthly_champion(client_id, db)
        await self._update_early_bird(client_id, db)
        await self._update_night_owl(client_id, db)
        await self._update_weekend_warrior(client_id, db)
        await self._update_streak(client_id, db)
        await self._update_perfect_week(client_id, db)
        await self._update_badge_collector(client_id, db)
        await db.commit()

    async def on_class_attended(self, client_id: int, db: AsyncSession) -> None:
        """Call after a client attends a class."""
        await self._update_class_enthusiast(client_id, db)
        await self._update_badge_collector(client_id, db)
        await db.commit()

    async def on_plan_completed(self, client_id: int, db: AsyncSession) -> None:
        """Call when a training plan status becomes COMPLETED."""
        await self._update_training_plan_completion(client_id, db)
        await self._update_badge_collector(client_id, db)
        await db.commit()

    # ── Check-in achievements ─────────────────────────────────────────────────

    async def _update_gym_rat(self, client_id: int, db: AsyncSession) -> None:
        """Total gym check-ins: 10 / 25 / 50 / 100 / 250"""
        result = await db.execute(
            select(func.count(Attendance.id))
            .where(Attendance.clientID == client_id)
        )
        count = result.scalar() or 0
        await self._apply_progress("gym_rat", client_id, count, db)

    async def _update_monthly_champion(self, client_id: int, db: AsyncSession) -> None:
        """Visits within the current calendar month: 5 / 10 / 20 / 35 / 50"""
        now = datetime.now(timezone.utc)
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        result = await db.execute(
            select(func.count(Attendance.id))
            .where(
                Attendance.clientID      == client_id,
                Attendance.checked_in >= month_start,
            )
        )
        count = result.scalar() or 0
        await self._apply_progress("monthly_champion", client_id, count, db)

    async def _update_early_bird(self, client_id: int, db: AsyncSession) -> None:
        """Check-ins before 07:00 (hour < 7)"""
        result = await db.execute(
            select(func.count(Attendance.id))
            .where(
                Attendance.clientID    == client_id,
                Attendance.check_in_hour < 7,
            )
        )
        count = result.scalar() or 0
        await self._apply_progress("early_bird", client_id, count, db)

    async def _update_night_owl(self, client_id: int, db: AsyncSession) -> None:
        """Check-ins after 20:00 (hour >= 20)"""
        result = await db.execute(
            select(func.count(Attendance.id))
            .where(
                Attendance.clientID    == client_id,
                Attendance.check_in_hour >= 20,
            )
        )
        count = result.scalar() or 0
        await self._apply_progress("night_owl", client_id, count, db)

    async def _update_weekend_warrior(self, client_id: int, db: AsyncSession) -> None:
        """Check-ins on Friday or Saturday (per requirements: days_of_week = friday/saturday)"""
        result = await db.execute(
            select(func.count(Attendance.id))
            .where(
                Attendance.clientID   == client_id,
                Attendance.day_of_week.in_(["friday", "saturday"]),
            )
        )
        count = result.scalar() or 0
        await self._apply_progress("weekend_warrior", client_id, count, db)

    async def _update_streak(self, client_id: int, db: AsyncSession) -> None:
        """Consecutive check-in days: 3 / 7 / 30 / 90 / 365"""
        current_streak = await self._calculate_current_streak(client_id, db)
        await self._apply_progress("consistency", client_id, current_streak, db)

    async def _update_perfect_week(self, client_id: int, db: AsyncSession) -> None:
        """Number of weeks in which the client checked in on 5 distinct days."""
        # Count weeks that have ≥ 5 distinct check-in dates
        # ISO week: Monday=1, Sunday=7
        result = await db.execute(
            select(
                func.count(distinct(Attendance.check_in_date)).label("days"),
                func.date_trunc("week", Attendance.checked_in).label("week_start"),
            )
            .where(Attendance.clientID == client_id)
            .group_by(func.date_trunc("week", Attendance.checked_in))
            .having(func.count(distinct(Attendance.check_in_date)) >= 5)
        )
        perfect_weeks = len(result.all())
        await self._apply_progress("perfect_week", client_id, perfect_weeks, db)

    # ── Class achievements ────────────────────────────────────────────────────

    async def _update_class_enthusiast(self, client_id: int, db: AsyncSession) -> None:
        return
        # """Total classes attended: 5 / 15 / 30 / 60 / 120"""
        # result = await db.execute(
        #     select(func.count(ClientClassEnrollment.enrollmentID))
        #     .where(ClientClassEnrollment.clientID == client_id)
        # )
        # count = result.scalar() or 0
        # await self._apply_progress("class_enthusiast", client_id, count, db)

    # ── Training plan achievements ────────────────────────────────────────────

    async def _update_training_plan_completion(self, client_id: int, db: AsyncSession) -> None:
        """Completed training plans: 1 / 3 / 5 / 10 / 20"""
        result = await db.execute(
            select(func.count(TrainingPlan.planID))
            .where(
                TrainingPlan.clientID == client_id,
                TrainingPlan.status   == PlanStatus.COMPLETED,
                TrainingPlan.is_active == True,  # only count active (latest) versions
            )
        )
        count = result.scalar() or 0
        await self._apply_progress("training_plan_completion", client_id, count, db)

    # ── Badge Collector ───────────────────────────────────────────────────────

    async def _update_badge_collector(self, client_id: int, db: AsyncSession) -> None:
        """Recalculate total unlocked badges and update badge_collector chain."""
        result = await db.execute(
            select(func.count(ClientAchievement.id))
            .where(
                ClientAchievement.clientID   == client_id,
                ClientAchievement.is_unlocked == True,
            )
        )
        unlocked_count = result.scalar() or 0
        await self._apply_progress("badge_collector", client_id, unlocked_count, db)

    # ── Core level progression engine ─────────────────────────────────────────

    async def _apply_progress(
        self,
        chain_key: str,
        client_id: int,
        raw_value: int,
        db: AsyncSession,
    ) -> None:
        """
        Given a chain_key (e.g. "gym_rat") and a raw progress value:
        1. Find the currently active level for this client.
        2. Update current_value (capped at target).
        3. If target reached → unlock, activate next level with carry-forward value.
        4. Repeat until no more levels or target not met.
        """
        # Load all levels in this chain ordered by target (Bronze first)
        result = await db.execute(
            select(Achievement)
            .where(Achievement.chain_key == chain_key)
            .order_by(Achievement.target)
        )
        levels: List[Achievement] = result.scalars().all()
        if not levels:
            logger.warning(f"No achievements found for chain '{chain_key}'")
            return

        # Load or create client rows for every level in this chain
        ca_map: dict[int, ClientAchievement] = {}
        for lvl in levels:
            res = await db.execute(
                select(ClientAchievement).where(
                    ClientAchievement.clientID      == client_id,
                    ClientAchievement.achievementID == lvl.achievementID,
                )
            )
            ca = res.scalar_one_or_none()
            if ca:
                ca_map[lvl.achievementID] = ca

        # Walk through levels in order
        for i, lvl in enumerate(levels):
            # --- Prerequisite check ---
            # Level 0 (Bronze) always starts active.
            # Higher levels only exist once the previous is unlocked.
            if i > 0:
                prev_lvl = levels[i - 1]
                prev_ca  = ca_map.get(prev_lvl.achievementID)
                if not prev_ca or not prev_ca.is_unlocked:
                    # This level is still locked — don't touch it
                    break

            # --- Get or create the ClientAchievement row ---
            ca = ca_map.get(lvl.achievementID)
            if ca is None:
                ca = ClientAchievement(
                    clientID      = client_id,
                    achievementID = lvl.achievementID,
                    current_value = 0,
                    best_value    = 0,
                    is_unlocked   = False,
                )
                db.add(ca)
                ca_map[lvl.achievementID] = ca

            if ca.is_unlocked:
                # Already done — progress carry means raw_value covers this level
                continue

            # --- Update progress with carry-forward ---
            ca.current_value = min(raw_value, lvl.target)
            if raw_value > ca.best_value:
                ca.best_value = raw_value

            # --- Unlock check ---
            if raw_value >= lvl.target:
                ca.is_unlocked = True
                ca.unlocked_at = datetime.now(timezone.utc)
                logger.info(
                    f"🎉 Client {client_id} unlocked [{lvl.key}] "
                    f"(value={raw_value}, target={lvl.target})"
                )
                # If there is a next level, create its row so it becomes visible
                if i + 1 < len(levels):
                    next_lvl = levels[i + 1]
                    if next_lvl.achievementID not in ca_map:
                        next_ca = ClientAchievement(
                            clientID      = client_id,
                            achievementID = next_lvl.achievementID,
                            current_value = raw_value,   # carry forward
                            best_value    = raw_value,
                            is_unlocked   = False,
                        )
                        db.add(next_ca)
                        ca_map[next_lvl.achievementID] = next_ca
                # Continue loop — maybe raw_value crosses multiple levels at once
            else:
                # Not unlocked yet; this is the active level — stop here
                break

    # ── Streak calculation ────────────────────────────────────────────────────

    async def _calculate_current_streak(self, client_id: int, db: AsyncSession) -> int:
        """
        Current consecutive-day streak ending today (or yesterday).
        Uses check_in_date (pre-computed in gym local tz).
        Multiple check-ins on the same day count as one.
        """
        result = await db.execute(
            select(Attendance.check_in_date)
            .where(
                Attendance.clientID    == client_id,
                Attendance.check_in_date.isnot(None),
            )
            .order_by(Attendance.check_in_date.desc())
        )
        raw_dates = result.scalars().all()
        if not raw_dates:
            return 0

        unique_dates = sorted(set(raw_dates), reverse=True)
        today = date.today()

        # Streak must include today or yesterday
        if unique_dates[0] < today - timedelta(days=1):
            return 0

        streak   = 0
        expected = unique_dates[0]   # start from most-recent check-in date
        for d in unique_dates:
            if d == expected:
                streak  += 1
                expected = expected - timedelta(days=1)
            else:
                break

        return streak

    # ── Read helpers ──────────────────────────────────────────────────────────

    async def get_client_achievements(
        self, client_id: int, db: AsyncSession
    ) -> list[dict]:
        """
        Return only active (unlocked or currently active) achievements for a client.
        Hides future locked levels per requirements.
        """
        result = await db.execute(
            select(Achievement, ClientAchievement)
            .outerjoin(
                ClientAchievement,
                and_(
                    Achievement.achievementID == ClientAchievement.achievementID,
                    ClientAchievement.clientID == client_id,
                )
            )
            .order_by(Achievement.chain_key, Achievement.target)
        )
        rows = result.all()

        # Group by chain; expose only unlocked rows + first non-unlocked per chain
        visible: list[dict] = []
        current_chain       = None
        found_active        = False

        for ach, ca in rows:
            if ach.chain_key != current_chain:
                current_chain = ach.chain_key
                found_active  = False

            is_unlocked = bool(ca and ca.is_unlocked)

            if is_unlocked:
                visible.append(self._format(ach, ca))
                continue

            if not found_active:
                # This is the active (visible but not yet done) level
                found_active = True
                visible.append(self._format(ach, ca))
            # else: future locked levels — hidden

        return visible

    @staticmethod
    def _format(ach: Achievement, ca: Optional[ClientAchievement]) -> dict:
        current = ca.current_value if ca else 0
        target  = ach.target or 1
        return {
            "achievementID"      : ach.achievementID,
            "key"                : ach.key,
            "chain_key"          : ach.chain_key,
            "name"               : ach.name,
            "description"        : ach.description,
            "icon"               : ach.icon_emoji or "🏅",
            "difficulty"         : ach.difficulty,
            "category"           : ach.category,
            "target"             : target,
            "unit"               : ach.unit,
            "current_value"      : current,
            "best_value"         : ca.best_value if ca else 0,
            "current_streak"     : ca.current_streak if ca else 0,
            "longest_streak"     : ca.longest_streak if ca else 0,
            "is_unlocked"        : bool(ca and ca.is_unlocked),
            "unlocked_at"        : ca.unlocked_at if ca else None,
            "progress_percentage": min(100, round((current / target) * 100)),
        }


achievement_engine = AchievementEngine()
