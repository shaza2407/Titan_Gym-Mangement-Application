# app/routers/client_schedule.py

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import date
from app.database import get_session
from app.dependencies.auth import require_client
from app.models.client import Client
from app.schemas.schedule_schema import ClientScheduleStatsResponse
from app.services.client_schedule import (
    get_client_schedule_stats,
    get_my_classes,
    browse_classes,
    get_weekly_schedule,
    enroll,
    unenroll,
)

router = APIRouter(prefix="/client/schedule", tags=["Client Schedule"])


async def get_client_or_404(userID: int, db: AsyncSession) -> Client:
    result = await db.execute(select(Client).where(Client.userID == userID))
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(404, "Client not found")
    return client


# GET /client/schedule/stats
@router.get("/stats", response_model=ClientScheduleStatsResponse)
async def schedule_stats(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session)
):
    client = await get_client_or_404(current_user.userID, db)
    stats = await get_client_schedule_stats(client.clientID, db)
    return ClientScheduleStatsResponse(**stats)


# GET /client/schedule/my-classes
@router.get("/my-classes")
async def my_classes(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session)
):
    client = await get_client_or_404(current_user.userID, db)
    return await get_my_classes(client.clientID, db)


# GET /client/schedule/browse?day=monday
@router.get("/browse")
async def browse(
    day: str | None = None,
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session)
):
    client = await get_client_or_404(current_user.userID, db)
    return await browse_classes(client.clientID, db, day_filter=day)


# GET /client/schedule/weekly
@router.get("/weekly")
async def weekly_schedule(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session)
):
    client = await get_client_or_404(current_user.userID, db)
    return await get_weekly_schedule(client.clientID, db)


# POST /client/schedule/enroll/{session_id}?class_date=2026-06-01
@router.post("/enroll/{session_id}")
async def enroll_class(
    session_id: int,
    class_date: date = Query(...),
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session)
):
    client = await get_client_or_404(current_user.userID, db)
    result = await enroll(session_id, client.clientID, class_date, db)
    if "error" in result:
        raise HTTPException(400, result["error"])
    return result


# DELETE /client/schedule/unenroll/{session_id}?class_date=2026-06-01
@router.delete("/unenroll/{session_id}")
async def unenroll_class(
    session_id: int,
    class_date: date = Query(...),
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session)
):
    client = await get_client_or_404(current_user.userID, db)
    result = await unenroll(session_id, client.clientID, class_date, db)
    if "error" in result:
        raise HTTPException(400, result["error"])
    return result