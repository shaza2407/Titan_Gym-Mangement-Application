from datetime import date, datetime, timedelta, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.models.class_session import ClassSession
from app.models.class_request import ClassRequest, RequestStatus
from app.models.coach import Coach
from app.schemas.coach_schemas import (
    ClassSessionResponse,
    ClassRequestResponse,
    CreateClassRequestPayload,
    ScheduleStatsResponse,
)
from app.dependencies.auth import require_coach

router = APIRouter(prefix="/coach", tags=["Coach"])

@router.get("/schedule/stats", response_model=ScheduleStatsResponse)
async def get_schedule_stats(
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

    pending_requests = await db.scalar(
        select(func.count()).select_from(ClassRequest).filter(
            ClassRequest.coach_id == coach_id,
            ClassRequest.status == RequestStatus.PENDING,
        )
    ) or 0

    return ScheduleStatsResponse(
        weekly_classes=weekly_classes,
        total_clients=total_clients,
        pending_requests=pending_requests,
    )


@router.get("/schedule/this-week", response_model=list[ClassSessionResponse])
async def get_weekly_schedule(
    db: AsyncSession = Depends(get_session),
    coach: Coach = Depends(require_coach),
):
    coach_id = coach.coachID
    today = date.today()
    end_of_week = today + timedelta(days=7)

    # Get ClassSession records
    result = await db.execute(
        select(ClassSession).filter(
            ClassSession.coach_id == coach_id,
            ClassSession.date >= today,
            ClassSession.date <= end_of_week,
        ).order_by(ClassSession.date.asc(), ClassSession.start_time.asc())
    )
    sessions = result.scalars().all()

    # Get approved ClassRequest records for this week
    req_result = await db.execute(
        select(ClassRequest).filter(
            ClassRequest.coach_id == coach_id,
            ClassRequest.status == RequestStatus.APPROVED,
            ClassRequest.requested_date >= today,
            ClassRequest.requested_date <= end_of_week,
        ).order_by(ClassRequest.requested_date.asc(), ClassRequest.requested_time.asc())
    )
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
    
    # Sort by date and time
    responses.sort(key=lambda x: (x.date, x.start_time))
    return responses


@router.get("/classes")
async def get_my_classes(
    db: AsyncSession = Depends(get_session),
    coach: Coach = Depends(require_coach),
):
    coach_id = coach.coachID

    result = await db.execute(
        select(ClassSession).filter(ClassSession.coach_id == coach_id)
    )
    all_classes = result.scalars().all()

    classes_map = {}
    for c in all_classes:
        if c.title not in classes_map:
            classes_map[c.title] = {
                "title": c.title,
                "schedule_summary": "Check schedule for days",
                "current_clients": c.current_clients,
                "max_clients": c.max_clients,
            }
    return list(classes_map.values())


@router.get("/class-requests", response_model=list[ClassRequestResponse])
async def get_requests_list(
    db: AsyncSession = Depends(get_session),
    coach: Coach = Depends(require_coach),
):
    coach_id = coach.coachID

    result = await db.execute(
        select(ClassRequest).filter(
            ClassRequest.coach_id == coach_id
        ).order_by(ClassRequest.created_at.desc())
    )
    return result.scalars().all()


@router.post("/class-requests", status_code=201)
async def request_new_class(
    payload: CreateClassRequestPayload,
    db: AsyncSession = Depends(get_session),
    coach: Coach = Depends(require_coach),
):
    coach_id = coach.coachID

    new_request = ClassRequest(
        coach_id=coach_id,
        class_name=payload.class_name,
        gym_location=payload.gym_location or "Unknown",
        requested_date=payload.requested_date,
        requested_time=payload.requested_time,
        duration=payload.duration,
        max_capacity=payload.max_capacity,
        reason_for_request=payload.reason,
        status=RequestStatus.PENDING,
        created_at=datetime.now(timezone.utc),
    )

    db.add(new_request)
    await db.commit()
    await db.refresh(new_request)

    return {"message": "Class request submitted successfully", "request_id": new_request.id}