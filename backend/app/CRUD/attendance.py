from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, cast, Date
from datetime import date
from app.models.attendance import Attendance
from app.models.gym_clients_membership import GymClientMembership, ClientMembershipStatus

async def get_membership(clientID: int, db: AsyncSession) -> GymClientMembership:
    result = await db.execute(
        select(GymClientMembership).where(GymClientMembership.clientID == clientID)
    )
    return result.scalar_one_or_none()


async def already_checked_in_today(membershipID: int, db: AsyncSession) -> bool:
    today = date.today()
    result = await db.execute(
        select(Attendance).where(
            Attendance.membershipID == membershipID,
            cast(Attendance.checked_in, Date) == today
        )
    )
    return result.scalar_one_or_none() is not None


async def record_checkin(membershipID: int, db: AsyncSession) -> Attendance:
    attendance = Attendance(membershipID=membershipID)
    db.add(attendance)
    await db.commit()
    await db.refresh(attendance)
    return attendance


async def get_recent_checkins(membershipID: int, db: AsyncSession, limit: int = 10):
    result = await db.execute(
        select(Attendance)
        .where(Attendance.membershipID == membershipID)
        .order_by(Attendance.checked_in.desc())
        .limit(limit)
    )
    return result.scalars().all()