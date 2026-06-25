# app/services/coach_dashboard.py

from http.client import HTTPException

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import date, timedelta
from app.models.class_session import ClassSession
from app.models.gym_coachs_membership import GymCoachMembership
from app.models.coach import Coach
from app.services.coach.coach_schedule import ( 
    _count_enrolled,
    _next_occurrence,
    get_gym_name,
)
from app.models.gym_clients_membership import GymClientMembership
from app.models.gym_coachs_membership import GymCoachMembership


# ── Dashboard Stats ───────────────────────────────────────────────────────────

async def get_coach_dashboard_stats(coachID: int, db: AsyncSession) -> dict:
    today = date.today()
    end_of_week = today + timedelta(days=6)
    day_names = ["monday", "tuesday", "wednesday",
                 "thursday", "friday", "saturday", "sunday"]

    # Get all coach classes
    sessions_result = await db.execute(
        select(ClassSession).where(ClassSession.coach_id == coachID)
    )
    sessions = sessions_result.scalars().all()

    # Weekly classes — recurring classes that fall in next 7 days
    # + one-time classes in next 7 days
    weekly_classes = 0
    days_in_window = set()
    for i in range(7):
        d = today + timedelta(days=i)
        days_in_window.add(day_names[d.weekday()])

    for s in sessions:
        if s.is_recurring and s.day_of_week and s.day_of_week in days_in_window:
            weekly_classes += 1
        elif not s.is_recurring and s.date and today <= s.date <= end_of_week:
            weekly_classes += 1

    clients_query = (
        select(func.count(func.distinct(GymClientMembership.clientID)))
        .join(GymCoachMembership, GymClientMembership.gymID == GymCoachMembership.gymID)
        .where(GymCoachMembership.coachID == coachID)
    )
    total_clients = await db.execute(clients_query)
    total_clients = total_clients.scalar() or 0

    # Active gyms
    gyms_result = await db.execute(
        select(func.count(GymCoachMembership.gymID)).where(
            GymCoachMembership.coachID == coachID
        )
    )
    active_gyms = gyms_result.scalar() or 0

    return {
        "weekly_classes": weekly_classes,
        "total_clients": total_clients,
        "active_gyms":    active_gyms,
    }


# ── Upcoming Classes (for dashboard) ─────────────────────────────────────────

async def get_upcoming_classes(coachID: int, db: AsyncSession, limit: int = 3) -> list:
    today = date.today()
    day_names = ["monday", "tuesday", "wednesday",
                 "thursday", "friday", "saturday", "sunday"]
    today_name = day_names[today.weekday()]

    sessions_result = await db.execute(
        select(ClassSession).where(ClassSession.coach_id == coachID)
    )
    sessions = sessions_result.scalars().all()

    todays_classes = []
    for s in sessions:
        gym_name = await get_gym_name(s.gymID, db) if s.gymID else None

        if s.is_recurring and s.day_of_week and s.day_of_week.lower() == today_name:
            count = await _count_enrolled(s.id, today, db)
            todays_classes.append({
                "id":              s.id,
                "title":           s.title,
                "day_of_week":     s.day_of_week,
                "date":            None,
                "start_time":      s.start_time,
                "duration":        s.duration,
                "gym_name":        gym_name,
                "current_clients": count,
                "max_clients":     s.max_clients,
            })
        elif not s.is_recurring and s.date == today:
            count = await _count_enrolled(s.id, today, db)
            todays_classes.append({
                "id":              s.id,
                "title":           s.title,
                "day_of_week":     s.day_of_week,
                "date":            s.date,
                "start_time":      s.start_time,
                "duration":        s.duration,
                "gym_name":        gym_name,  
                "current_clients": count,
                "max_clients":     s.max_clients,
            })

    todays_classes.sort(key=lambda x: x["start_time"])
    return todays_classes[:limit]

