from app.models.gym_coachs_membership import GymCoachMembership

from datetime import date
from typing import List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies.auth import get_session, require_coach
from app.schemas.coach.coach_schemas import CoachGymResponse
from app.services.coach.coach_gyms import get_coach_active_gyms, get_coach_announcements
from app.models.coach import Coach
from app.models.User import User
from app.services.admin.admin_schedule import get_all_classes

router = APIRouter(prefix="/coach/gyms", tags=["Coach Gyms"])


async def _resolve_coach_id(user: User, db: AsyncSession) -> int:
    result = await db.execute(select(Coach.coachID).where(Coach.userID == user.userID))
    coach_id = result.scalar_one_or_none()
    if coach_id is None:
        raise HTTPException(404, "Coach record not found")
    return coach_id


async def verify_coach_gym(coachID: int, gymID: int, db: AsyncSession) -> int:
    # Check if the coach is a member of this gym
    result = await db.execute(
        select(GymCoachMembership).where(
            GymCoachMembership.coachID == coachID,
            GymCoachMembership.gymID == gymID
        )
    )
    membership = result.scalar_one_or_none()
    if not membership:
        raise HTTPException(403, "You are not a member of this gym")
    return gymID


@router.get("/my-gyms", response_model=List[CoachGymResponse])
async def get_my_gyms(current_user: User = Depends(require_coach), db: AsyncSession = Depends(get_session)):
    return await get_coach_active_gyms(current_user.userID, db)


@router.get("/my-announcements")
async def get_announcements(
    gym_id: int | None = Query(None),
    coach: User = Depends(require_coach),
    db: AsyncSession = Depends(get_session),
):
    if gym_id is not None:
        coach_id = await _resolve_coach_id(coach, db)
        await verify_coach_gym(coach_id, gym_id, db)
    return await get_coach_announcements(coach.userID, db, gym_id=gym_id)


# GET /coach/gyms/classes?gym_id=1
@router.get("/classes")
async def all_classes(
    gym_id: int = Query(...),
    from_date: date | None = Query(None),
    week_start: date | None = Query(None),
    week_end: date | None = Query(None),
    coach: User = Depends(require_coach),
    db: AsyncSession = Depends(get_session),
):
    coach_id = await _resolve_coach_id(coach, db)
    gymID = await verify_coach_gym(coach_id, gym_id, db)
    return await get_all_classes(gymID, db, from_date=from_date, week_start=week_start, week_end=week_end)