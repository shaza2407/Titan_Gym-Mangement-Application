# app/services/client/client_attendance.py

from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, cast, Date
from datetime import datetime, date, timezone
from app.models.attendance import Attendance
from app.models.gym_clients_membership import GymClientMembership
from app.services.client.client_utils import get_gym_or_404

_DOW = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]


async def already_checked_in_today(client_id: int, gym_id: int, db: AsyncSession) -> bool:
    today = date.today()
    result = await db.execute(
        select(Attendance).where(
            Attendance.clientID == client_id,
            Attendance.gymID == gym_id,
            cast(Attendance.checked_in, Date) == today,
        )
    )
    return result.scalar_one_or_none() is not None


def _assert_can_checkin(membership: GymClientMembership | None):
    if not membership:
        raise HTTPException(400, "Not connected to any gym")
    if membership.status == "suspended":
        raise HTTPException(403, "Your membership is suspended")
    if membership.subscription_end < date.today():
        raise HTTPException(403, "Your subscription has expired")


def _build_checkin_message(gym_name: str) -> str:
    now = datetime.now(timezone.utc)
    dow = _DOW[now.weekday()]
    if now.hour < 7:
        return f"Early bird! Checked in at {gym_name} 🌅"
    if now.hour >= 20:
        return f"Night owl mode! Checked in at {gym_name} 🦉"
    if dow in ("friday", "saturday"):
        return f"Weekend warrior! Checked in at {gym_name} ⚔️"
    return f"Checked in successfully at {gym_name}"


async def _get_active_membership_or_403(
    client_id: int, gym_id: int, db: AsyncSession
) -> GymClientMembership:
    result = await db.execute(
        select(GymClientMembership).where(
            GymClientMembership.clientID == client_id,
            GymClientMembership.gymID == gym_id,
        )
    )
    membership = result.scalar_one_or_none()
    _assert_can_checkin(membership)
    return membership


async def record_checkin(client_id: int, gym_id: int, db: AsyncSession) -> Attendance:
    await _get_active_membership_or_403(client_id, gym_id, db)

    now = datetime.now()
    attendance = Attendance(
        clientID=client_id,
        gymID=gym_id,
        checked_in=now,
        day_of_week=_DOW[now.weekday()],
    )
    db.add(attendance)
    await db.commit()
    await db.refresh(attendance)
    return attendance


async def perform_checkin(
    client_id: int,
    membership: GymClientMembership,
    qr_code: str,
    db: AsyncSession,
) -> tuple[Attendance, str]:

    _assert_can_checkin(membership)

    if await already_checked_in_today(client_id, membership.gymID, db):
        raise HTTPException(400, "Already checked in today")

    gym = await get_gym_or_404(membership.gymID, db)

    if not gym.QRCode:
        raise HTTPException(500, "Gym QR code is not configured")
    if qr_code.strip() != gym.QRCode.strip():
        raise HTTPException(400, "This QR code doesn't belong to your gym")
    attendance = await record_checkin(client_id, membership.gymID, db)
    message = _build_checkin_message(gym.gymName)

    return attendance, message


async def get_recent_checkins(client_id: int, gym_id: int, db: AsyncSession, limit: int = 50):
    result = await db.execute(
        select(Attendance)
        .where(
            Attendance.clientID == client_id,
            Attendance.gymID == gym_id,
        )
        .order_by(Attendance.checked_in.desc())
        .limit(limit)
    )
    return result.scalars().all()


def get_checkin_block_reason(membership: GymClientMembership | None) -> str | None:
    if not membership:
        return "not_connected"
    if membership.status == "suspended":
        return "suspended"
    if membership.subscription_end < date.today():
        return "expired"
    return None