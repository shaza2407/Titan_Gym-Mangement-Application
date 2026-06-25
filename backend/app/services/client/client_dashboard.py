from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, cast, Date, distinct
from datetime import date, timedelta
from app.models.attendance import Attendance


async def get_dashboard_stats(client_id: int, gym_id: int, db: AsyncSession) -> dict:
    today = date.today()
    start_of_week = today - timedelta(days=today.weekday())

    total_result = await db.execute(
        select(func.count(Attendance.id)).where(
            Attendance.clientID == client_id,
            Attendance.gymID == gym_id,
        )
    )
    total_visits = total_result.scalar() or 0

    week_result = await db.execute(
        select(func.count(distinct(cast(Attendance.checked_in, Date)))).where(
            Attendance.clientID == client_id,
            Attendance.gymID == gym_id,
            cast(Attendance.checked_in, Date) >= start_of_week,
        )
    )
    days_this_week = week_result.scalar() or 0

    streak_result = await db.execute(
        select(cast(Attendance.checked_in, Date))
        .where(
            Attendance.clientID == client_id,
            Attendance.gymID == gym_id,
        )
        .distinct()
        .order_by(cast(Attendance.checked_in, Date).desc())
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