# app/routers/client_attendance.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import date
from app.database import get_session
from app.dependencies.auth import require_client
from app.models import Client, GymClientMembership
from app.schemas.attendance_schema import (
    CheckinStatusResponse,
    CheckinResponse,
    CheckinHistoryResponse
)
from app.CRUD.attendance import (
    get_membership,
    already_checked_in_today,
    record_checkin,
    get_recent_checkins
)

router = APIRouter(prefix="/client", tags=["Client Attendance"])


async def get_client_or_404(userID: int, db: AsyncSession):
    result = await db.execute(select(Client).where(Client.userID == userID))
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(404, "Client not found")
    return client


# GET /client/checkin-status
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

    attendance = await record_checkin(membership.id, db)
    return CheckinResponse(
        message="Checked in successfully",
        checked_in=str(attendance.checked_in)
    )


# GET /client/checkins
@router.get("/checkins", response_model=CheckinHistoryResponse)
async def get_checkins(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session)
):
    client = await get_client_or_404(current_user.userID, db)
    membership = await get_membership(client.clientID, db)

    if not membership:
        return CheckinHistoryResponse(checkins=[])

    records = await get_recent_checkins(membership.id, db)
    return CheckinHistoryResponse(checkins=records)