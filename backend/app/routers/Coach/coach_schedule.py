# app/routers/coach_schedule.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_session
from app.dependencies.auth import require_coach
from app.models.coach import Coach
from app.schemas.coach_schemas import (
    CoachScheduleStatsResponse,
    CreateClassRequestPayload,
)
from app.services.coach_schedule import (
    get_schedule_stats,
    get_weekly_schedule,
    get_my_classes,
    get_class_requests,
    create_class_request,
    get_coach_gymID,
)

router = APIRouter(prefix="/coach/schedule", tags=["Coach Schedule"])


async def get_coach_or_404(userID: int, db: AsyncSession) -> Coach:
    result = await db.execute(select(Coach).where(Coach.userID == userID))
    coach = result.scalar_one_or_none()
    if not coach:
        raise HTTPException(404, "Coach not found")
    return coach


# GET /coach/schedule/stats
@router.get("/stats", response_model=CoachScheduleStatsResponse)
async def schedule_stats(
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    stats = await get_schedule_stats(coach.coachID, db)
    return CoachScheduleStatsResponse(**stats)


# GET /coach/schedule/weekly
@router.get("/weekly")
async def weekly(
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    return await get_weekly_schedule(coach.coachID, db)


# GET /coach/schedule/my-classes
@router.get("/my-classes")
async def my_classes(
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    return await get_my_classes(coach.coachID, db)


# GET /coach/schedule/requests
@router.get("/requests")
async def class_requests(
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    return await get_class_requests(coach.coachID, db)


# POST /coach/schedule/requests
@router.post("/requests", status_code=201)
async def create_request(
    payload: CreateClassRequestPayload,
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    gymID = await get_coach_gymID(coach.coachID, db)
    if not gymID:
        raise HTTPException(400, "You are not connected to any gym")
    result = await create_class_request(coach.coachID, gymID, payload, db)
    return result