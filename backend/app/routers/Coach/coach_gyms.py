from datetime import date
from typing import List
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies.auth import get_session, require_coach
from app.schemas.coach.coach_schemas import CoachGymResponse
from app.services.coach.coach_gyms import (
    get_coach_active_gyms, 
    get_coach_announcements, 
    verify_coach_gym
)
# Reusing the helper from schedule services
from app.services.coach.coach_schedule import get_coach_or_404
from app.models.User import User
from app.services.admin.admin_schedule import get_all_classes

router = APIRouter(prefix="/coach/gyms", tags=["Coach Gyms"])


# GET /coach/gyms/my-gyms
@router.get("/my-gyms", response_model=List[CoachGymResponse])
async def get_my_gyms(
    current_user: User = Depends(require_coach), 
    db: AsyncSession = Depends(get_session)
):
    return await get_coach_active_gyms(current_user.userID, db)


@router.get("/my-announcements")
async def get_announcements(
    gym_id: int | None = Query(None),
    coach: User = Depends(require_coach),
    db: AsyncSession = Depends(get_session),
):
    if gym_id is not None:
        coach_obj = await get_coach_or_404(coach.userID, db)
        await verify_coach_gym(coach_obj.coachID, gym_id, db)
        
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
    coach_obj = await get_coach_or_404(coach.userID, db)
    verified_gym_id = await verify_coach_gym(coach_obj.coachID, gym_id, db)
    
    return await get_all_classes(
        verified_gym_id, 
        db, 
        from_date=from_date, 
        week_start=week_start, 
        week_end=week_end
    )