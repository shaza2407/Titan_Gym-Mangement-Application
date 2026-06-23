# app/routers/client_schedule.py

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
import asyncio
from sqlalchemy import select ,delete
from datetime import date ,time ,datetime , timedelta
from app.database import get_session
from app.dependencies.auth import require_client
from app.models.client import Client
from app.models.notification import Notification
from app.schemas.schedule_schema import ClientScheduleStatsResponse
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from app.services.class_notifications import notify_class_reminder
from app.services.client_schedule import (
    get_client_schedule_stats,
    get_my_classes,
    browse_classes,
    get_weekly_schedule,
    enroll,
    unenroll,
)
from app.services.achievement_engine import achievement_engine

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



scheduler = AsyncIOScheduler()
scheduler.start()
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

    # schedule notification for class day before class by 2 hours
    class_start = datetime.combine(class_date, result.get("start_time"))
    run_time = class_start - timedelta(hours=2)

    if run_time <= datetime.now():
    # time already passed, notify immediately
        asyncio.create_task(notify_class_reminder(
        session_id, client.clientID, result.get("title", "your class")))
    else:
        scheduler.add_job(
            notify_class_reminder,
            trigger="date",
            run_date=run_time,
            args=[session_id, client.clientID, result.get("title", "your class")],
            id=f"class_reminder_{session_id}_{client.clientID}_{class_date}",
            replace_existing=True,
        )

    # Trigger achievement update for enrolling in a class
    await achievement_engine.on_class_attended(client.clientID, db)

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

    # cancel scheduled notification
    job_id = f"class_reminder_{session_id}_{client.clientID}_{class_date}"
    if scheduler.get_job(job_id):
        scheduler.remove_job(job_id)

    # delete saved notification
    await db.execute(
        delete(Notification).where(
            Notification.user_id == current_user.userID,
            Notification.type == "class-reminder",
            Notification.data["session_id"].as_string() == str(session_id),
        )
    )
    await db.commit()

    return result
