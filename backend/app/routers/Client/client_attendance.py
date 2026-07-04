# app/routers/Client/client_attendance.py

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_session
from app.dependencies.auth import require_client
from app.schemas.client.attendance_schema import (
    CheckinStatusResponse, CheckinResponse,
    CheckinRecord, CheckinHistoryResponse, CheckinRequest,
)
from app.services.client.client_utils import get_client_or_404, get_membership
from app.services.client.client_attendance import (
    already_checked_in_today, get_checkin_block_reason,
    perform_checkin, get_recent_checkins,
)
from app.services.client.achievement_engine import achievement_engine

router = APIRouter(prefix="/client", tags=["Client Attendance"])


@router.get("/checkin-status", response_model=CheckinStatusResponse)
async def checkin_status(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session)
):
    client = await get_client_or_404(current_user.userID, db)
    membership = await get_membership(client.clientID, db)

    reason = get_checkin_block_reason(membership)
    if reason:
        return CheckinStatusResponse(can_checkin=False, reason=reason)

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

    attendance, message = await perform_checkin(
        client.clientID, membership, payload.qr_code, db
    )

    await achievement_engine.on_checkin(client.clientID, db)

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