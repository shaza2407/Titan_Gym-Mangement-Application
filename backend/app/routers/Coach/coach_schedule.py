# app/routers/coach_schedule.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_session
from app.dependencies.auth import require_coach
from app.models.coach import Coach
from app.schemas.coach_schemas import (
    CoachGymLookUpResponse,
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
    remove_class,
    remove_class_request,
    get_coach_gyms_lookup
)
from app.services import coach_schedule

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

# - Edited: use payload.gym_id directly from selection dropdown 
# POST /coach/schedule/requests
@router.post("/requests", status_code=201)
async def create_request(
    payload: CreateClassRequestPayload,
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    result = await create_class_request(coach.coachID, payload.gym_id, payload, db)
    return result


# DELETE /coach/schedule/my-classes/{class_id}
@router.delete("/my-classes/{class_id}")
async def delete_class(
    class_id: int,
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(
        current_user.userID,
        db,
    )

    success = await remove_class(
        coach.coachID,
        class_id,
        db,
    )

    if not success:
        raise HTTPException(
            status_code=404,
            detail="Class not found",
        )

    return {"message": "Class removed successfully"}


# -Added: new endpoint to delete a requested class.
@router.delete("/requests/{request_id}")
async def delete_request(request_id: int, current_user=Depends(require_coach), db: AsyncSession = Depends(get_session)):
    coach = await get_coach_or_404(current_user.userID, db)
    success = await remove_class_request(coach.coachID, request_id, db)
    if not success:
        raise HTTPException(status_code=404, detail="Class request not found")
    return {"message":"Request cancelled and deleted successfully"}


# -Added: new endpoint to get gyms for a coach
@router.get("/gyms", response_model=list[CoachGymLookUpResponse])
async def read_coach_gyms(current_user=Depends(require_coach), db: AsyncSession=Depends(get_session)):
    coach = await get_coach_or_404(current_user.userID, db)
    return await get_coach_gyms_lookup(coach.coachID, db)