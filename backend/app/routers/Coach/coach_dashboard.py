# app/routers/coach_dashboard.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_session
from app.dependencies.auth import require_coach
from app.models.coach import Coach
from app.schemas.coach.coach_schemas import (
    CoachDashboardStatsResponse,
    CoachProfileUpdate,
    CoachProfileResponse,
)
from app.services.coach.coach_dashboard import (
    get_coach_dashboard_stats,
    get_upcoming_classes,
)
from app.services.coach.coach_schedule import get_coach_or_404
from app.services.coach.coach_profile import (
    get_coach_profile,
    update_coach_profile,
)

router = APIRouter(prefix="/coach", tags=["Coach"])




# GET /coach/me
@router.get("/me")
async def get_me(
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    return {
        "userID":  current_user.userID,
        "coachID": coach.coachID,
        "name":    current_user.name,
        "email":   current_user.email,
    }


# GET /coach/dashboard
@router.get("/dashboard", response_model=CoachDashboardStatsResponse)
async def dashboard(
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    stats = await get_coach_dashboard_stats(coach.coachID, db)
    return CoachDashboardStatsResponse(**stats)


# GET /coach/dashboard/upcoming
@router.get("/dashboard/upcoming")
async def upcoming(
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    return await get_upcoming_classes(coach.coachID, db)


# GET /coach/profile
@router.get("/profile", response_model=CoachProfileResponse)
async def get_profile(
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    profile = await get_coach_profile(current_user.userID, db)
    if not profile:
        raise HTTPException(404, "Profile not found")
    return profile


# PUT /coach/profile
@router.put("/profile", response_model=CoachProfileResponse)
async def update_profile(
    payload: CoachProfileUpdate,
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    updated = await update_coach_profile(current_user.userID, payload, db)
    if not updated:
        raise HTTPException(404, "Profile not found")
    return updated


# GET /coach/specializations
@router.get("/specializations")
async def get_specializations():
    return {"specializations": [
        "Strength Training", "HIIT", "Yoga", "Pilates", "CrossFit",
        "Cardio", "Nutrition", "Bodybuilding", "Mobility & Flexibility",
        "Boxing & MMA", "Swimming", "Rehabilitation", "Weight Loss",
        "Endurance & Running", "Functional Training",
    ]}