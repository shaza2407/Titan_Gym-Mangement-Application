"""
app/routers/checkin.py
───────────────────────
POST /checkin/         – Client scans QR code → creates an Attendance record, fires achievements
GET  /checkin/history  – Returns client's past attendance records
"""

from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, cast, Date

from app.database import get_session
from app.dependencies.auth import require_client
from app.models.client import Client
from app.models.attendance import Attendance
from app.models.Gym import Gym
from app.schemas.achievement_schemas import CheckInRequest, CheckInResponse
from app.services.achievement_engine import achievement_engine

router = APIRouter(prefix="/checkin", tags=["Check-In"])

# Day-of-week mapping aligned with requirements (Friday + Saturday = weekend)
_DOW = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]


async def _get_client(current_user, db: AsyncSession) -> Client:
    result = await db.execute(
        select(Client).where(Client.userID == int(current_user.userID))
    )
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(status_code=403, detail="Only clients can check in.")
    return client


@router.post(
    "/",
    response_model=CheckInResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Record a gym attendance after QR scan",
)
async def check_in(
    req: CheckInRequest,
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client = await _get_client(current_user, db)

    gym_result = await db.execute(select(Gym).where(Gym.gymID == req.gymID))
    gym = gym_result.scalar_one_or_none()
    if not gym:
        raise HTTPException(status_code=404, detail="Gym not found.")

    now       = datetime.now(timezone.utc)
    today_utc = now.date()

    # Prevent duplicate attendance at the same gym on the same calendar day
    dup = await db.execute(
        select(Attendance).where(
            Attendance.clientID == client.clientID,
            Attendance.gymID    == req.gymID,
            cast(Attendance.checked_in, Date) == today_utc,
        )
    )
    if dup.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Already checked in at this gym today.",
        )

    # Compute pre-indexed fields for fast achievement queries
    dow = _DOW[now.weekday()]   # weekday(): 0=Monday … 6=Sunday

    new_attendance = Attendance(
        clientID      = client.clientID,
        gymID         = req.gymID,
        checked_in    = now,
        check_in_hour = now.hour,
        check_in_date = today_utc,
        day_of_week   = dow,
    )
    db.add(new_attendance)
    await db.commit()
    await db.refresh(new_attendance)

    # ── Fire achievement engine ──────────────────────────────────────────────
    await achievement_engine.on_checkin(client.clientID, db)

    message = f"Welcome to {gym.gymName}! Keep it up 💪"
    if now.hour < 7:
        message = f"Early bird! Welcome to {gym.gymName} 🌅"
    elif now.hour >= 20:
        message = f"Night owl mode! Welcome to {gym.gymName} 🦉"
    elif dow in ("friday", "saturday"):
        message = f"Weekend warrior! Welcome to {gym.gymName} ⚔️"

    return CheckInResponse(
        checkInID     = new_attendance.id,
        gymID         = new_attendance.gymID,
        checked_in_at = new_attendance.checked_in,
        message       = message,
    )


@router.get(
    "/history",
    summary="Get attendance history for the authenticated client",
)
async def get_checkin_history(
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client = await _get_client(current_user, db)
    result = await db.execute(
        select(Attendance)
        .where(Attendance.clientID == client.clientID)
        .order_by(Attendance.checked_in.desc())
        .limit(100)
    )
    return result.scalars().all()
