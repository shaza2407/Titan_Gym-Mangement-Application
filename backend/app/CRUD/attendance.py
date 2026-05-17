from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, cast, Date, distinct
from datetime import date,timedelta
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


async def get_dashboard_stats(membershipID: int, db: AsyncSession) -> dict:
    today = date.today()
    start_of_week = today - timedelta(days=today.weekday())

    # Total visits
    total_result = await db.execute(
        select(func.count(Attendance.id)).where(
            Attendance.membershipID == membershipID
        )
    )
    total_visits = total_result.scalar() or 0

    # Days this week
    week_result = await db.execute(
        select(func.count(distinct(cast(Attendance.checked_in, Date)))).where(
            Attendance.membershipID == membershipID,
            cast(Attendance.checked_in, Date) >= start_of_week
        )
    )
    days_this_week = week_result.scalar() or 0

    # Current streak
    streak_result = await db.execute(
        select(cast(Attendance.checked_in, Date))
        .where(Attendance.membershipID == membershipID)
        .order_by(Attendance.checked_in.desc())
    )
    all_dates = [row[0] for row in streak_result.fetchall()]
    unique_dates = sorted(set(all_dates), reverse=True)

    streak = 0
    check_date = today
    for d in unique_dates:
        if d == check_date or d == check_date - timedelta(days=1):
            streak += 1
            check_date = d - timedelta(days=1)
        else:
            break

    return {
        "total_visits":   total_visits,
        "days_this_week": days_this_week,
        "current_streak": streak,
    }