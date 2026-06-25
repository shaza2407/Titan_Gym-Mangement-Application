from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, cast, Date
from datetime import datetime, date
from app.models.attendance import Attendance

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


async def record_checkin(client_id: int, gym_id: int, db: AsyncSession) -> Attendance:
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