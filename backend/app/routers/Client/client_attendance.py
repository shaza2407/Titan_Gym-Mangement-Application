#app/routers/Client/client_attendance.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, date, timezone
from app.database import get_session
from app.dependencies.auth import require_client
from app.models.Gym import Gym
from app.schemas.client.attendance_schema import (
    CheckinStatusResponse, CheckinResponse,
    CheckinRecord, CheckinHistoryResponse, CheckinRequest,
)
from app.services.client.client_shared import get_client_or_404, get_membership
from app.services.client.client_attendance import (
    already_checked_in_today, record_checkin, get_recent_checkins
)
from app.services.coach.achievement_engine import achievement_engine

router = APIRouter(prefix="/client", tags=["Client Attendance"])


@router.get("/checkin-status", response_model=CheckinStatusResponse)
async def checkin_status(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session)
):
    client = await get_client_or_404(current_user.userID, db)
    membership = await get_membership(client.clientID, db)

    if not membership:
        return CheckinStatusResponse(can_checkin=False, reason="not_connected")
    if membership.status == "suspended":
        return CheckinStatusResponse(can_checkin=False, reason="suspended")
    if membership.subscription_end < date.today():
        return CheckinStatusResponse(can_checkin=False, reason="expired")
    if await already_checked_in_today(client.clientID, membership.gymID, db):
        return CheckinStatusResponse(can_checkin=False, reason="already_checked_in")

    return CheckinStatusResponse(
        can_checkin=True,
        reason="ok",
        membershipID=membership.id,
        subscription=membership.subscription,
        subscription_end=str(membership.subscription_end),
        status=membership.status,
    )


@router.post("/checkin", response_model=CheckinResponse)
async def checkin(
    payload: CheckinRequest,
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session)
):
    client = await get_client_or_404(current_user.userID, db)
    membership = await get_membership(client.clientID, db)

    if not membership:
        raise HTTPException(400, "Not connected to any gym")
    if membership.status == "suspended":
        raise HTTPException(403, "Your membership is suspended")
    if membership.subscription_end < date.today():
        raise HTTPException(403, "Your subscription has expired")
    if await already_checked_in_today(client.clientID, membership.gymID, db):
        raise HTTPException(400, "Already checked in today")

    gym_result = await db.execute(select(Gym).where(Gym.gymID == membership.gymID))
    gym = gym_result.scalar_one_or_none()
    if not gym:
        raise HTTPException(404, "Gym not found")

    expected_qr = f"TITAN-GYM-{gym.gymID}-{gym.gymName.upper().replace(' ', '-')}"
    if payload.qr_code.strip() != expected_qr:
        raise HTTPException(400, "This QR code doesn't belong to your gym")

    attendance = await record_checkin(client.clientID, membership.gymID, db)
    await achievement_engine.on_checkin(client.clientID, db)

    now = datetime.now(timezone.utc)
    dow = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"][now.weekday()]
    message = f"Checked in successfully at {gym.gymName}"
    if now.hour < 7:
        message = f"Early bird! Checked in at {gym.gymName} 🌅"
    elif now.hour >= 20:
        message = f"Night owl mode! Checked in at {gym.gymName} 🦉"
    elif dow in ("friday", "saturday"):
        message = f"Weekend warrior! Checked in at {gym.gymName} ⚔️"

    return CheckinResponse(
        message=message,
        checked_in=str(attendance.checked_in),
        day_of_week=attendance.day_of_week,
    )


@router.get("/checkins", response_model=CheckinHistoryResponse)
async def get_checkins(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session),
    limit: int = 50
):
    client = await get_client_or_404(current_user.userID, db)
    membership = await get_membership(client.clientID, db)

    if not membership:
        return CheckinHistoryResponse(checkins=[])

    records = await get_recent_checkins(client.clientID, membership.gymID, db, limit)

    return CheckinHistoryResponse(checkins=[
        CheckinRecord(id=r.id, checked_in=r.checked_in, day_of_week=r.day_of_week)
        for r in records
    ])