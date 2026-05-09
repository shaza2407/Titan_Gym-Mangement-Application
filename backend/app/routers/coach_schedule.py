
from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.class_request import ClassRequest, RequestStatus
from app.models.class_session import ClassSession

from app.database import get_session
from app.schemas.coach_schemas import (
    ScheduleStatsResponse, 
    MyClassesResponse,
    ClassSessionResponse,
    CreateClassRequestPayload,
    ClassRequestResponse

)
from datetime import datetime, timezone,date,timedelta

router = APIRouter()

@router.get("/{coach_id}/schedule/stats",response_model=ScheduleStatsResponse)
async def get_schedule_stats(coach_id: int, db: AsyncSession=Depends(get_session)):
    today = date.today()
    end_of_week = today + timedelta(days=7)

    # weekly classes
    weekly_query = select(func.count()).select_from(ClassSession).filter(
        ClassSession.coach_id == coach_id,
        ClassSession.date >= today,
        ClassSession.date <= end_of_week,
    )

    weekly_classes = await db.scalar(weekly_query) or 0

    # Total Clients
    clients_query = select(func.sum(ClassSession.current_clients)).filter(
        ClassSession.coach_id == coach_id
    )

    total_clients = await db.scalar(clients_query) or 0

    # pending requests
    pending_query = select(func.count()).select_from(ClassRequest).filter(
        ClassRequest.coach_id == coach_id,
        ClassRequest.status == RequestStatus.PENDING
    )
    pending_requests = await db.scalar(pending_query) or 0

    return ScheduleStatsResponse(
        weekly_classes=weekly_classes,
        total_clients=total_clients,
        pending_requests=pending_requests
    )


@router.get("/{coach_id}/schedule/this-week", response_model=list[ClassSessionResponse])
async def get_weekly_schedule(coach_id: int, db: AsyncSession=Depends(get_session)):
    today = date.today()
    end_of_week = today + timedelta(days=7)

    query = select(ClassSession).filter(
        ClassSession.coach_id == coach_id,
        ClassSession.date >= today,
        ClassSession.date <= end_of_week,
    ).order_by(ClassSession.date.asc(), ClassSession.start_time.asc())

    result = await db.execute(query)
    return result.scalars().all()



@router.get("/{coach_id}/classes/")
async def get_my_classes(coach_id: int, db: AsyncSession = Depends(get_session)):
    query = select(ClassSession).filter(ClassSession.coach_id==coach_id)
    result = await db.execute(query)
    all_classes = result.scalars().all()

    # 
    myClasses_map= {}
    for c in all_classes:
        if c.title not in myClasses_map:
            myClasses_map[c.title] = {
                "title":c.title,
                # "gym_id":c.gym_id,
                "schedule_summary": "Check schedule for days",
                "current_clients": c.current_clients,
                "max_clients":c.max_clients,
            }
    return list(myClasses_map.values())


@router.get("/{coach_id}/class-request",response_model=list[ClassRequestResponse])
async def get_requests_list(coach_id:int, db:AsyncSession=Depends(get_session)):
    query = select(ClassRequest).filter(
        ClassRequest.coach_id==coach_id
    ).order_by(ClassRequest.created_at.desc())

    result = await db.execute(query)
    return result.scalars().all()


@router.post("/{coach_id}/class_requests/",status_code=201)
async def request_new_class(coach_id: int, payload: CreateClassRequestPayload, db: AsyncSession = Depends(get_session)):

    new_request = ClassRequest(
        coach_id=coach_id,
        class_name=payload.class_name,
        gym_location=payload.gym_location or "Unknown",
        requested_date=payload.requested_date,
        requested_time=payload.requested_time,
        duration=payload.duration,
        max_capacity=payload.max_capacity,
        # gym_id = payload.gym_id,
        reason_for_request=payload.reason,
        status=RequestStatus.PENDING,
        created_at=datetime.now(timezone.utc)
    )

    db.add(new_request)
    await db.commit()
    await db.refresh(new_request)

    return {"message": "Class request submitted successfully", "request_id": new_request.id}
