# app/routers/achievements.py
"""
Endpoints
─────────
GET  /achievements/            – All badges + live progress for current client
POST /achievements/recalculate – Force full recalculation (admin / debug)

BUG FIXES applied:
1. require_client dependency added — previously any authenticated user (coach,
   admin) could call these endpoints; now only clients are allowed.
2. _get_client helper already raises 403 for non-clients, but the route itself
   had no role guard at the decorator level — belt-and-suspenders added.
3. goal_crusher logic was comparing time-elapsed instead of checking the
   plan's `status` column that was added to the model.  Fixed to use
   TrainingPlan.status == PlanStatus.COMPLETED.
4. _compute_streak had an off-by-one: the `expected` variable was set to
   `today` on entry but could advance past today causing an infinite match.
   Rewritten cleanly.
5. Division-by-zero guard added for percent calculation when ach.target == 0.
6. POST /recalculate was missing entirely — added.
"""

from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_session
from app.dependencies.auth import get_current_user, require_client
from app.models.client import Client
from app.models.check_in import CheckIn
from app.models.client_class_enrollment import ClientClassEnrollment
from app.models.training_plan import TrainingPlan, PlanStatus
from app.models.achievement import Achievement
from app.models.client_achievement import ClientAchievement
from app.schemas.achievement_schemas import AchievementProgressResponse

router = APIRouter(prefix="/achievements", tags=["Achievements"])


# ── Helper: resolve clientID ──────────────────────────────────────────────────

async def _get_client(current_user, db: AsyncSession) -> Client:
    result = await db.execute(
        select(Client).where(Client.userID == int(current_user.userID))
    )
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only clients can view achievements.",
        )
    return client


# ── Progress engine ───────────────────────────────────────────────────────────

async def _compute_progress(client_id: int, db: AsyncSession) -> dict[str, int]:
    now         = datetime.now(timezone.utc)
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    # 1. Monthly Champion
    monthly_result = await db.execute(
        select(func.count(CheckIn.checkInID)).where(
            CheckIn.clientID    == client_id,
            CheckIn.checked_in_at >= month_start,
        )
    )
    monthly_visits = monthly_result.scalar() or 0

    # 2. Class Enthusiast — distinct sessions attended
    class_result = await db.execute(
        select(func.count(ClientClassEnrollment.sessionID.distinct())).where(
            ClientClassEnrollment.clientID == client_id
        )
    )
    distinct_classes = class_result.scalar() or 0

    # 3. Early Bird — check-ins before 07:00
    early_result = await db.execute(
        select(func.count(CheckIn.checkInID)).where(
            CheckIn.clientID    == client_id,
            CheckIn.check_in_hour < 7,
        )
    )
    early_mornings = early_result.scalar() or 0

    # 4. Consistency King — current consecutive-day streak
    streak = await _compute_streak(client_id, db)

    # 5. Social Butterfly — group class enrollments
    group_result = await db.execute(
        select(func.count(ClientClassEnrollment.enrollmentID)).where(
            ClientClassEnrollment.clientID      == client_id,
            ClientClassEnrollment.is_group_class == 1,
        )
    )
    group_classes = group_result.scalar() or 0

    # 6. Goal Crusher — BUG FIX: use status column, not time arithmetic
    plans_result = await db.execute(
        select(func.count(TrainingPlan.planID)).where(
            TrainingPlan.clientID == client_id,
            TrainingPlan.status   == PlanStatus.COMPLETED,
        )
    )
    completed_plans = plans_result.scalar() or 0

    return {
        "monthly_champion": monthly_visits,
        "class_enthusiast": distinct_classes,
        "early_bird":       early_mornings,
        "consistency_king": streak,
        "social_butterfly": group_classes,
        "goal_crusher":     completed_plans,
    }


async def _compute_streak(client_id: int, db: AsyncSession) -> int:
    """Count consecutive calendar days the client has checked in (up to today)."""
    result = await db.execute(
        select(CheckIn.checked_in_at)
        .where(CheckIn.clientID == client_id)
        .order_by(CheckIn.checked_in_at.desc())
    )
    rows = result.scalars().all()
    if not rows:
        return 0

    # Collect unique UTC dates
    unique_dates = sorted(
        {
            r.date() if hasattr(r, "date") else r.replace(tzinfo=None).date()
            for r in rows
        },
        reverse=True,
    )

    today = datetime.now(timezone.utc).date()

    # BUG FIX: streak is broken if the last check-in wasn't today or yesterday
    if unique_dates[0] < today - timedelta(days=1):
        return 0

    streak   = 0
    expected = today
    for d in unique_dates:
        if d == expected:
            streak  += 1
            expected = expected - timedelta(days=1)
        elif d == today - timedelta(days=1) and streak == 0:
            # Allow yesterday as the start when there's no check-in today
            streak  += 1
            expected = d - timedelta(days=1)
        else:
            break
    return streak


# ── Shared upsert helper ──────────────────────────────────────────────────────

async def _build_response(db: AsyncSession, client_id: int) -> list[AchievementProgressResponse]:
    ach_result = await db.execute(select(Achievement).order_by(Achievement.achievementID))
    achievements = ach_result.scalars().all()

    ca_result = await db.execute(
        select(ClientAchievement).where(ClientAchievement.clientID == client_id)
    )
    saved = {row.achievementID: row for row in ca_result.scalars().all()}

    live_progress = await _compute_progress(client_id, db)

    response = []
    for ach in achievements:
        current     = live_progress.get(ach.key, 0)
        prev        = saved.get(ach.achievementID)
        is_unlocked = current >= ach.target
        unlocked_at = None

        if prev is None:
            ca = ClientAchievement(
                clientID      = client_id,
                achievementID = ach.achievementID,
                current_value = current,
                is_unlocked   = is_unlocked,
                unlocked_at   = datetime.now(timezone.utc) if is_unlocked else None,
            )
            db.add(ca)
            unlocked_at = ca.unlocked_at
        else:
            prev.current_value = current
            if is_unlocked and not prev.is_unlocked:
                prev.is_unlocked = True
                prev.unlocked_at = datetime.now(timezone.utc)
            unlocked_at = prev.unlocked_at

        # BUG FIX: guard against division-by-zero
        percent = 0
        if ach.target > 0:
            percent = min(100, round((current / ach.target) * 100))

        response.append(
            AchievementProgressResponse(
                achievementID = ach.achievementID,
                key           = ach.key,
                name          = ach.name,
                description   = ach.description,
                icon_emoji    = ach.icon_emoji,
                target        = ach.target,
                unit          = ach.unit,
                current_value = current,
                percent       = percent,
                is_unlocked   = is_unlocked,
                unlocked_at   = unlocked_at,
            )
        )

    await db.commit()
    return response


# ── GET /achievements/ ────────────────────────────────────────────────────────

@router.get(
    "/",
    response_model=list[AchievementProgressResponse],
    summary="Get all achievements with live progress for the authenticated client",
)
async def get_achievements(
    # BUG FIX: added require_client — previously coaches/admins could access this
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client = await _get_client(current_user, db)
    return await _build_response(db, client.clientID)


# ── POST /achievements/recalculate ────────────────────────────────────────────

@router.post(
    "/recalculate",
    response_model=list[AchievementProgressResponse],
    summary="Force a full recalculation of achievement progress (client only)",
)
async def recalculate_achievements(
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client = await _get_client(current_user, db)
    return await _build_response(db, client.clientID)
