# app/routers/Client/client_schedule.py

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
import asyncio
from datetime import date, datetime, timedelta
from app.database import get_session
from app.dependencies.auth import require_client
from app.schemas.shared.schedule_schema import ClientScheduleStatsResponse
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from app.services.notifications.class_notifications import notify_class_reminder
from app.services.client.client_utils import get_client_or_404
from app.services.client.client_schedule import (
    get_client_schedule_stats, get_my_classes, browse_classes,
    get_weekly_schedule, enroll, unenroll, delete_class_reminder_notifications,
)
from app.services.coach.achievement_engine import achievement_engine

router = APIRouter(prefix="/client/schedule", tags=["Client Schedule"])

scheduler = AsyncIOScheduler()
scheduler.start()


@router.get("/stats", response_model=ClientScheduleStatsResponse)
async def schedule_stats(current_user=Depends(require_client), db: AsyncSession = Depends(get_session)):
    client = await get_client_or_404(current_user.userID, db)
    stats = await get_client_schedule_stats(client.clientID, db)
    return ClientScheduleStatsResponse(**stats)


@router.get("/my-classes")
async def my_classes(current_user=Depends(require_client), db: AsyncSession = Depends(get_session)):
    client = await get_client_or_404(current_user.userID, db)
    return await get_my_classes(client.clientID, db)


@router.get("/browse")
async def browse(day: str | None = None, current_user=Depends(require_client), db: AsyncSession = Depends(get_session)):
    client = await get_client_or_404(current_user.userID, db)
    return await browse_classes(client.clientID, db, day_filter=day)


@router.get("/weekly")
async def weekly_schedule(current_user=Depends(require_client), db: AsyncSession = Depends(get_session)):
    client = await get_client_or_404(current_user.userID, db)
    return await get_weekly_schedule(client.clientID, db)


@router.post("/enroll/{session_id}")
async def enroll_class(session_id: int, class_date: date = Query(...), current_user=Depends(require_client), db: AsyncSession = Depends(get_session)):
    client = await get_client_or_404(current_user.userID, db)
    result = await enroll(session_id, client.clientID, class_date, db)
    if "error" in result:
        raise HTTPException(400, result["error"])

    class_start = datetime.combine(class_date, result.get("start_time"))
    run_time = class_start - timedelta(hours=2)

    if run_time <= datetime.now():
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
    await db.commit()
    await achievement_engine.on_class_attended(client.clientID, db)
    return result


@router.delete("/unenroll/{session_id}")
async def unenroll_class(session_id: int, class_date: date = Query(...), current_user=Depends(require_client), db: AsyncSession = Depends(get_session)):
    client = await get_client_or_404(current_user.userID, db)
    result = await unenroll(session_id, client.clientID, class_date, db)
    if "error" in result:
        raise HTTPException(400, result["error"])

    job_id = f"class_reminder_{session_id}_{client.clientID}_{class_date}"
    if scheduler.get_job(job_id):
        scheduler.remove_job(job_id)

    await delete_class_reminder_notifications(current_user.userID, session_id, db)
    return result