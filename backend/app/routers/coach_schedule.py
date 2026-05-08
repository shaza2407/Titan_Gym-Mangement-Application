
from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.class_request import ClassRequest, RequestStatus
from app.models.class_session import ClassSession

from app.database import get_session
from backend.app.schemas.coach_schemas import (
    ScheduleStatsResponse, 
    MyClassesResponse,
    ClassSessionResponse,
    CreateClassRequestPayload,
    ClassRequestResponse

)
from datetime import datetime, timezone,date,timedelta

router = APIRouter()


@router.post("/{coach_id}/class_requests/",status_code=201)
async def request_new_class(coach_id: int, payload: CreateClassRequestPayload, db: AsyncSession = Depends(get_session)):

    new_request = ClassRequest(
        coach_id=coach_id,
        class_name=payload.class_name,
        requested_date=payload.requested_date,
        requested_time=payload.requested_time,
        duration=payload.duration,
        max_capacity=payload.max_capacity,
        gym_id = payload.gym_id,
        reason_for_request=payload.reason,
        status=RequestStatus.PENDING,
        created_at=datetime.now(timezone.utc)
    )

    db.add(new_request)
    await db.commit()
    await db.refresh(new_request)

    return {"message": "Class request submitted successfully", "request_id": new_request.id}
