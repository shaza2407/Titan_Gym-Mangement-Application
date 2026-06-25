# app/routers/coach_schedule.py

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_session
from app.dependencies.auth import require_coach
from app.schemas.coach.coach_schemas import (
    CoachGymLookUpResponse,
    CoachScheduleStatsResponse,
    CreateClassRequestPayload,
)
from app.services.coach.coach_schedule import (
    get_schedule_stats,
    get_weekly_schedule,
    get_my_classes,
    get_class_requests,
    create_class_request,
    remove_class,
    remove_class_request,
    get_coach_gyms_lookup,
    get_coach_or_404
)

router = APIRouter(prefix="/coach/schedule", tags=["Coach Schedule"])


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
    return await create_class_request(coach.coachID, payload.gym_id, payload, db)    



# DELETE /coach/schedule/my-classes/{class_id}
@router.delete("/my-classes/{class_id}")
async def delete_class(
    class_id: int,
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    await remove_class(coach.coachID, class_id, db)
    return {"message": "Class removed successfully"}



# DELETE /coach/schedule/requests/{request_id}
@router.delete("/requests/{request_id}")
async def delete_request(
    request_id: int,
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    await remove_class_request(coach.coachID, request_id, db)
    return {"message": "Request cancelled and deleted successfully"}



# GET /coach/schedule/gyms
@router.get("/gyms", response_model=list[CoachGymLookUpResponse])
async def read_coach_gyms(
    current_user=Depends(require_coach), 
    db: AsyncSession=Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    return await get_coach_gyms_lookup(coach.coachID, db)