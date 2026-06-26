from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, cast, Date
from datetime import date, timedelta
from app.models.attendance import Attendance
from app.models.Gym import Gym
from app.schemas.client.attendance_schema import (
    AttendanceStatsResponse,
    WeeklyAttendanceResponse,
)


async def get_attendance_statistics(db: AsyncSession, gym: Gym):
    today = date.today()
    week_start = today - timedelta(days=6)

    # 1- Today's total
    today_result = await db.execute(
        select(func.count(Attendance.id))
        .where(
            Attendance.gymID == gym.gymID,
            cast(Attendance.checked_in, Date) == today,
        )
    )
    today_total = today_result.scalar_one_or_none() or 0

    # 2- This week total
    week_result = await db.execute(
        select(func.count(Attendance.id))
        .where(
            Attendance.gymID == gym.gymID,
            cast(Attendance.checked_in, Date) >= week_start,
        )
    )
    week_total = week_result.scalar_one_or_none() or 0

    return AttendanceStatsResponse(
        today_total=today_total,
        this_week=week_total,
    )


async def get_weekly_attendance_chart(db: AsyncSession, gym: Gym):
    today = date.today()
    week_start = today - timedelta(days=6)

    result = await db.execute(
        select(
            cast(Attendance.checked_in, Date).label("day"),
            func.count(Attendance.id).label("count"),
        ).where(
            Attendance.gymID == gym.gymID,
            cast(Attendance.checked_in, Date) >= week_start,
        ).group_by(cast(Attendance.checked_in, Date))
        .order_by(cast(Attendance.checked_in, Date))
    )

    rows = result.all()
    count_map = {r.day: r.count for r in rows}
    days = [
        {
            "day": (week_start + timedelta(days=i)).strftime("%a"),
            "count": count_map.get(week_start + timedelta(days=i), 0),
        }
        for i in range(7)
    ]
    return WeeklyAttendanceResponse(week_start=str(week_start), days=days)