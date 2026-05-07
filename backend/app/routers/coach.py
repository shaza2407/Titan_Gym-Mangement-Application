from datetime import date,datetime, timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from app.models.class_session import ClassSession, ClassRequest, RequestStatus
from app.schemas.coach import (ClassSessionResponse, DashboardStatsResponse, CoachCreate)
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_session
from app.models.coach import Coach

router = APIRouter()




@router.get("/{coach_id}/dashboard/upcoming-classes", response_model=list[ClassSessionResponse])
async def get_dashboard_upcoming_classes(coach_id: int, limit: int=3, db: AsyncSession = Depends(get_session)):

    
    now = datetime.now()
    current_date = now.date()
    current_time = now.time()

    query = select(ClassSession).filter(
        ClassSession.coach_id == coach_id,
        (ClassSession.date > current_date) |
        ((ClassSession.date == current_date) & (ClassSession.start_time > current_time))
    ).order_by(
        ClassSession.date.asc(),
        ClassSession.start_time.asc()
    ).limit(limit)

    result = await db.execute(query)
    upcoming_classes = result.scalars().all()

    return upcoming_classes



@router.get("/{coach_id}/dashboard",response_model=DashboardStatsResponse)
async def get_dashboard_stats(coach_id: int, db: AsyncSession = Depends(get_session)):

    today = date.today()
    end_of_Week = today + timedelta(days=7)

    # weekly classes
    weekly_query = select(func.count()).select_from(ClassSession).filter(
        ClassSession.coach_id == coach_id,
        ClassSession.date >= today,
        ClassSession.date <= end_of_Week
    )

    weekly_classes = await db.execute(weekly_query) or 0

    # total students
    students_query = select(func.sum(ClassSession.current_students)).filter(
        ClassSession.coach_id == coach_id
    )

    total_students = await db.execute(students_query) or 0

    # active gyms
    # gyms_query = select(func.count(ClassSession.gym_id.distinct())).filter(
    #     ClassSession.coach_id == coach_id
    # )
    # active_gyms = await db.execute(gyms_query) or 0

    # pending requests
    pending_query = select(func.count()).select_from(ClassRequest).filter(
        ClassRequest.coach_id == coach_id,
        ClassRequest.status == RequestStatus.PENDING
    )
    pending_requests = await db.execute(pending_query) or 0

    return DashboardStatsResponse(
        weekly_classes=weekly_classes.scalar() or 0,
        total_students=total_students.scalar() or 0,
        # active_gyms=active_gyms.scalar() or 0,
        pending_requests=pending_requests.scalar() or 0
    )



# @router.post("/{coach_id}/class_requests/",status_code=201)
# async def request_new_class(coach_id: int, payload: CreateClassRequestPayload, db: AsyncSession = Depends(get_session)):

#     new_request = ClassRequest(
#         coach_id=coach_id,
#         class_type=payload.class_type,
#         requested_date=payload.requested_date,
#         requested_time=payload.requested_time,
#         gym_id = payload.gym_id,
#         status=RequestStatus.pending
#     )

#     db.add(new_request)
#     await db.commit()
#     await db.refresh(new_request)

#     return {"message": "Class request submitted successfully", "request_id": new_request.id}
