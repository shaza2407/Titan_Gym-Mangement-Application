from datetime import date, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.models.class_session import ClassSession
from app.models import User
from app.models.class_request import ClassRequest, RequestStatus
from app.models.coach import Coach
from app.schemas.coach_schemas import ClassSessionResponse, DashboardStatsResponse
from app.dependencies.auth import require_coach

router = APIRouter(prefix="/coach", tags=["Coach"])


async def get_coach_or_404(userID: int, db: AsyncSession) -> Coach:
    result = await db.execute(select(Coach).where(Coach.userID == userID))
    coach = result.scalar_one_or_none()
    if not coach:
        raise HTTPException(status_code=404, detail="Coach profile not found")
    return coach


# GET /coach/me
# Returns basic coach info
# Frontend uses this right after sign in
@router.get("/me")
async def get_me(
    current_user: User = Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    return {
        "userID": current_user.userID,
        "name": current_user.name,
        "email": current_user.email,
    }


# GET /coach/profile
@router.get("/profile")
async def get_profile(
    current_user: User = Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    return {
        "userID": current_user.userID,
        "name": current_user.name,
        "email": current_user.email,
        "phone": current_user.phone,
    }


@router.get("/dashboard/upcoming-classes", response_model=list[ClassSessionResponse])
async def get_dashboard_upcoming_classes(
    limit: int = 3,
    db: AsyncSession = Depends(get_session),
    coach: Coach = Depends(require_coach),
):
    coach_id = coach.coachID
    now = datetime.now()
    current_date = now.date()
    current_time = now.time()

    # Get upcoming ClassSession records
    query = select(ClassSession).filter(
        ClassSession.coach_id == coach_id,
        (ClassSession.date > current_date) |
        ((ClassSession.date == current_date) & (ClassSession.start_time > current_time))
    ).order_by(
        ClassSession.date.asc(),
        ClassSession.start_time.asc()
    ).limit(limit)

    result = await db.execute(query)
    sessions = result.scalars().all()

    # Get approved ClassRequest records that are upcoming
    req_query = select(ClassRequest).filter(
        ClassRequest.coach_id == coach_id,
        ClassRequest.status == RequestStatus.APPROVED,
        (ClassRequest.requested_date > current_date) |
        ((ClassRequest.requested_date == current_date) & (ClassRequest.requested_time > current_time))
    ).order_by(
        ClassRequest.requested_date.asc(),
        ClassRequest.requested_time.asc()
    ).limit(limit)

    req_result = await db.execute(req_query)
    approved_requests = req_result.scalars().all()

    # Convert both to ClassSessionResponse format
    responses = []
    
    for session in sessions:
        responses.append(ClassSessionResponse(
            id=session.id,
            title=session.title,
            date=session.date,
            start_time=session.start_time,
            coach_id=session.coach_id,
            current_clients=session.current_clients,
            max_clients=session.max_clients,
            is_approved_request=False,
        ))
    
    for req in approved_requests:
        responses.append(ClassSessionResponse(
            id=req.id,
            title=req.class_name,
            date=req.requested_date,
            start_time=req.requested_time,
            coach_id=req.coach_id,
            current_clients=0,
            max_clients=req.max_capacity,
            is_approved_request=True,
        ))
    
    # Sort by date and time, then limit to requested amount
    responses.sort(key=lambda x: (x.date, x.start_time))
    return responses[:limit]


@router.get("/dashboard", response_model=DashboardStatsResponse)
async def get_dashboard_stats(
    db: AsyncSession = Depends(get_session),
    coach: Coach = Depends(require_coach),
):
    coach_id = coach.coachID

    today = date.today()
    end_of_week = today + timedelta(days=7)

    weekly_classes = await db.scalar(
        select(func.count()).select_from(ClassSession).filter(
            ClassSession.coach_id == coach_id,
            ClassSession.date >= today,
            ClassSession.date <= end_of_week,
        )
    ) or 0

    total_clients = await db.scalar(
        select(func.sum(ClassSession.current_clients)).filter(
            ClassSession.coach_id == coach_id
        )
    ) or 0

    return DashboardStatsResponse(
        weekly_classes=weekly_classes,
        total_clients=total_clients,
    )