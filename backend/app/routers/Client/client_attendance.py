# app/routers/client_attendance.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, date, timezone
from app.database import get_session
from app.dependencies.auth import require_client
from app.models import Client, GymClientMembership, Gym  # Added Gym import
from app.schemas.attendance_schema import (
    CheckinStatusResponse,
    CheckinResponse,
    CheckinRecord,
    CheckinHistoryResponse,
    CheckinRequest,
)
from app.services.attendance import (
    get_membership,
    already_checked_in_today,
    record_checkin,
    get_recent_checkins
)
from app.services.achievement_engine import achievement_engine  # Add achievement engine

router = APIRouter(prefix="/client", tags=["Client Attendance"])


async def get_client_or_404(userID: int, db: AsyncSession):
    result = await db.execute(select(Client).where(Client.userID == userID))
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(404, "Client not found")
    return client


async def get_gym_from_membership(membership: GymClientMembership, db: AsyncSession):
    """Get gym details from membership"""
    result = await db.execute(select(Gym).where(Gym.gymID == membership.gymID))
    return result.scalar_one_or_none()


# GET /client/checkin-status
@router.get("/checkin-status", response_model=CheckinStatusResponse)
async def checkin_status(
        current_user=Depends(require_client),
        db: AsyncSession = Depends(get_session)
):
    from sqlalchemy import func, and_
    client = await get_client_or_404(current_user.userID, db)
    membership = await get_membership(client.clientID, db)

    if not membership:
        return CheckinStatusResponse(can_checkin=False, reason="not_connected")

    if membership.status == "suspended":
        return CheckinStatusResponse(can_checkin=False, reason="suspended")

    if membership.subscription_end < date.today():
        return CheckinStatusResponse(can_checkin=False, reason="expired")

    if await already_checked_in_today(membership.id, db):
        return CheckinStatusResponse(can_checkin=False, reason="already_checked_in")

    return CheckinStatusResponse(
        can_checkin=True,
        reason="ok",
        membershipID=membership.id,
        subscription=membership.subscription,
        subscription_end=str(membership.subscription_end),
        status=membership.status,
    )


# POST /client/checkin
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

    if await already_checked_in_today(membership.id, db):
        raise HTTPException(400, "Already checked in today")

    # Get gym details and validate the scanned code matches this gym
    gym = await get_gym_from_membership(membership, db)
    if not gym:
        raise HTTPException(404, "Gym not found")

    expected_qr_data = f"TITAN-GYM-{gym.gymID}-{gym.gymName.upper().replace(' ', '-')}"
    if payload.qr_code.strip() != expected_qr_data:
        raise HTTPException(400, "This QR code doesn't belong to your gym")

    gym_name = gym.gymName if gym else "Gym"

    # Record check-in with all fields populated
    attendance = await record_checkin(
        membershipID=membership.id,
        db=db
    )

    # ── Fire achievement engine ──────────────────────────────────────────────
    await achievement_engine.on_checkin(membership.clientID, db)

    # Custom welcome message based on check-in time
    now = datetime.now(timezone.utc)
    dow = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"][now.weekday()]

    message = f"Checked in successfully at {gym_name}"
    if now.hour < 7:
        message = f"Early bird! Checked in at {gym_name} 🌅"
    elif now.hour >= 20:
        message = f"Night owl mode! Checked in at {gym_name} 🦉"
    elif dow in ("friday", "saturday"):
        message = f"Weekend warrior! Checked in at {gym_name} ⚔️"

    return CheckinResponse(
        message=message,
        checked_in=str(attendance.checked_in),
        day_of_week = attendance.day_of_week
    )


# GET /client/checkins
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

    records = await get_recent_checkins(membership.id, db, limit)

    # Format response with additional pre-indexed fields
    checkins_list = []
    for record in records:
        checkins_list.append(
            CheckinRecord(
                id=record.id,
                checked_in=record.checked_in,
                day_of_week=record.day_of_week,
            )
        )

    return CheckinHistoryResponse(checkins=checkins_list)
