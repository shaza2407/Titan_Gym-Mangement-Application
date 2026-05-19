from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, cast, Date, distinct, and_
from datetime import datetime, timezone, date, timedelta
from app.models.attendance import Attendance
from app.models.gym_clients_membership import GymClientMembership, ClientMembershipStatus

# Day-of-week mapping ( monday is always index 0 )
_DOW = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

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
            Attendance.check_in_date == today  # Use pre-indexed field
        )
    )
    return result.scalar_one_or_none() is not None


async def record_checkin(membershipID: int, clientID: int, gymID: int, db: AsyncSession) -> Attendance:
    """Record check-in with all pre-indexed fields populated"""
    now = datetime.now(timezone.utc)
    today_utc = now.date()
    dow = _DOW[now.weekday()]
    check_in_hour = now.hour

    attendance = Attendance(
        membershipID=membershipID,
        clientID=clientID,
        gymID=gymID,
        checked_in=now,
        check_in_hour=check_in_hour,
        check_in_date=today_utc,
        day_of_week=dow,
    )
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

    # Days this week — use pre-indexed check_in_date
    week_result = await db.execute(
        select(func.count(distinct(Attendance.check_in_date))).where(
            Attendance.membershipID == membershipID,
            Attendance.check_in_date >= start_of_week
        )
    )
    days_this_week = week_result.scalar() or 0

    # Streak calculation using pre-indexed dates
    streak_result = await db.execute(
        select(Attendance.check_in_date)
        .where(Attendance.membershipID == membershipID)
        .distinct()
        .order_by(Attendance.check_in_date.desc())
    )
    unique_dates = [row[0] for row in streak_result.fetchall()]

    streak = 0
    if unique_dates:
        if unique_dates[0] >= today - timedelta(days=1):
            check_date = unique_dates[0]
            for d in unique_dates:
                if d == check_date:
                    streak += 1
                    check_date = check_date - timedelta(days=1)
                else:
                    break

    return {
        "total_visits":   total_visits,
        "days_this_week": days_this_week,
        "current_streak": streak,
    }