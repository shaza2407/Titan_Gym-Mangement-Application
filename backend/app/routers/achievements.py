"""
app/routers/achievements.py
────────────────────────────
Endpoints:

  Client:
    POST /checkins                        – check in to gym → triggers badge evaluation
    GET  /achievements/dashboard          – stats summary
    GET  /achievements/earned             – earned badges list
    GET  /achievements/in-progress        – in-progress badges list

  Admin:
    POST   /admin/achievements            – create badge definition
    GET    /admin/achievements            – list all badge definitions
    PATCH  /admin/achievements/{id}       – update / disable badge
"""

from datetime import date, datetime, timezone
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_session
from app.dependencies.auth import get_current_user, require_admin
from app.models.achievement import Achievement, UserAchievement, UserCheckin, AchievementType
from app.models.gym_machine import Gym
from app.schemas.achievement_schema import (
    AchievementCreate, AchievementResponse,
    CheckinRequest, CheckinResponse,
    AchievementDashboard, EarnedBadge, InProgressBadge,
)
from app.services.achievement_service import AchievementEngine
from app.services.streak_service import calculate_streak

router = APIRouter(tags=["Achievements"])


# ── Check-in ──────────────────────────────────────────────────────────────────

@router.post(
    "/checkins",
    response_model=CheckinResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Record a gym check-in and evaluate achievements",
)
async def checkin(
    payload: CheckinRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    user_id = current_user.userID
    today   = date.today()

    # Prevent duplicate check-in same day
    existing = await db.execute(
        select(UserCheckin).where(
            UserCheckin.userID       == user_id,
            UserCheckin.checkin_date == today,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Already checked in today.",
        )

    # Validate gym if provided
    if payload.gymID:
        gym_result = await db.execute(select(Gym).where(Gym.gymID == payload.gymID))
        if not gym_result.scalar_one_or_none():
            raise HTTPException(status_code=404, detail="Gym not found.")

    checkin_record = UserCheckin(
        userID       = user_id,
        gymID        = payload.gymID,
        checkin_date = today,
        checkin_time = datetime.now(timezone.utc),
    )
    db.add(checkin_record)
    await db.flush()

    # Evaluate achievements
    engine     = AchievementEngine(db)
    new_badges = await engine.evaluate_checkin(user_id)

    await db.refresh(checkin_record)

    earned_list = [
        EarnedBadge(
            achievement_id = b.achievement_id,
            title          = b.title,
            description    = b.description,
            icon_url       = b.icon_url,
            reward_points  = b.reward_points,
            earned_at      = datetime.now(timezone.utc),
        )
        for b in new_badges
    ]

    return CheckinResponse(
        success    = True,
        message    = "Checked in successfully!",
        checkin_id = checkin_record.id,
        new_badges = earned_list,
    )


# ── Achievement Dashboard ─────────────────────────────────────────────────────

@router.get(
    "/achievements/dashboard",
    response_model=AchievementDashboard,
    summary="Get achievement stats for the current user",
)
async def achievement_dashboard(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    user_id = current_user.userID

    # Total active badges
    total_result = await db.execute(
        select(func.count()).select_from(Achievement).where(Achievement.is_active == True)
    )
    total = total_result.scalar() or 0

    # User achievements
    ua_result = await db.execute(
        select(UserAchievement).where(UserAchievement.userID == user_id)
    )
    user_achievements = ua_result.scalars().all()
    earned      = sum(1 for ua in user_achievements if ua.is_completed)
    in_progress = sum(1 for ua in user_achievements if not ua.is_completed)

    completion_pct = round((earned / total * 100), 1) if total else 0.0

    # Streak
    checkin_result = await db.execute(
        select(UserCheckin.checkin_date)
        .where(UserCheckin.userID == user_id)
        .order_by(UserCheckin.checkin_date)
    )
    dates   = [row[0] for row in checkin_result.all()]
    streak  = calculate_streak(dates)

    return AchievementDashboard(
        total                 = total,
        earned                = earned,
        in_progress           = in_progress,
        completion_percentage = completion_pct,
        current_streak        = streak,
    )


# ── Earned Badges ─────────────────────────────────────────────────────────────

@router.get(
    "/achievements/earned",
    response_model=List[EarnedBadge],
    summary="List all earned badges for the current user",
)
async def earned_badges(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    user_id = current_user.userID

    result = await db.execute(
        select(UserAchievement, Achievement)
        .join(Achievement, UserAchievement.achievement_id == Achievement.achievement_id)
        .where(
            UserAchievement.userID        == user_id,
            UserAchievement.is_completed  == True,
        )
        .order_by(UserAchievement.completed_at.desc())
    )

    rows = result.all()
    return [
        EarnedBadge(
            achievement_id = ach.achievement_id,
            title          = ach.title,
            description    = ach.description,
            icon_url       = ach.icon_url,
            reward_points  = ach.reward_points,
            earned_at      = ua.completed_at,
        )
        for ua, ach in rows
    ]


# ── In-Progress Badges ────────────────────────────────────────────────────────

@router.get(
    "/achievements/in-progress",
    response_model=List[InProgressBadge],
    summary="List in-progress badges for the current user",
)
async def in_progress_badges(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    user_id = current_user.userID

    result = await db.execute(
        select(UserAchievement, Achievement)
        .join(Achievement, UserAchievement.achievement_id == Achievement.achievement_id)
        .where(
            UserAchievement.userID       == user_id,
            UserAchievement.is_completed == False,
            Achievement.is_active        == True,
        )
        .order_by(UserAchievement.progress_value.desc())
    )

    rows = result.all()
    badges = []
    for ua, ach in rows:
        pct       = round((ua.progress_value / ach.target_value * 100), 1) if ach.target_value else 0
        remaining = max(0, ach.target_value - ua.progress_value)
        badges.append(
            InProgressBadge(
                achievement_id = ach.achievement_id,
                title          = ach.title,
                description    = ach.description,
                icon_url       = ach.icon_url,
                progress       = ua.progress_value,
                target         = ach.target_value,
                percentage     = pct,
                remaining      = remaining,
            )
        )
    return badges


# ── Admin: Manage Badge Definitions ──────────────────────────────────────────

@router.post(
    "/admin/achievements",
    response_model=AchievementResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Admin: create a badge definition",
)
async def create_achievement(
    payload: AchievementCreate,
    _admin=Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    ach = Achievement(**payload.model_dump())
    db.add(ach)
    await db.commit()
    await db.refresh(ach)
    return ach


@router.get(
    "/admin/achievements",
    response_model=List[AchievementResponse],
    summary="Admin: list all badge definitions",
)
async def list_achievements(
    _admin=Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    result = await db.execute(select(Achievement).order_by(Achievement.achievement_id))
    return result.scalars().all()


@router.patch(
    "/admin/achievements/{achievement_id}",
    response_model=AchievementResponse,
    summary="Admin: update / disable a badge",
)
async def update_achievement(
    achievement_id: int,
    payload: AchievementCreate,
    _admin=Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    result = await db.execute(
        select(Achievement).where(Achievement.achievement_id == achievement_id)
    )
    ach = result.scalar_one_or_none()
    if not ach:
        raise HTTPException(status_code=404, detail="Achievement not found")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(ach, field, value)

    await db.commit()
    await db.refresh(ach)
    return ach