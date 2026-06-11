# app/services/coach_schedule.py

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import date, timedelta
from app.models.class_session import ClassSession
from app.models.class_request import ClassRequest, RequestStatus
from app.models.class_enrollment import ClassEnrollment
from app.models.gym_coachs_membership import GymCoachMembership
from app.models.Gym import Gym
from app.models.coach import Coach
from app.models import User
from app.schemas.coach_schemas import CreateClassRequestPayload


# ── Helpers ───────────────────────────────────────────────────────────────────

async def get_coach_gymID(coachID: int, db: AsyncSession) -> int | None:
    result = await db.execute(
        select(GymCoachMembership.gymID).where(
            GymCoachMembership.coachID == coachID
        )
    )
    return result.scalar_one_or_none()


async def get_gym_name(gymID: int, db: AsyncSession) -> str | None:
    result = await db.execute(
        select(Gym.gymName).where(Gym.gymID == gymID)  
    )
    return result.scalar_one_or_none()


def _next_occurrence(day_name: str) -> date:
    days = ["monday", "tuesday", "wednesday", "thursday",
            "friday", "saturday", "sunday"]
    today = date.today()
    target = days.index(day_name.lower())
    days_ahead = (target - today.weekday()) % 7
    if days_ahead == 0:
        days_ahead = 7
    return today + timedelta(days=days_ahead)


async def _count_enrolled(session_id: int, class_date: date, db: AsyncSession) -> int:
    result = await db.scalar(
        select(func.count(ClassEnrollment.id)).where(
            ClassEnrollment.session_id == session_id,
            ClassEnrollment.class_date == class_date,
        )
    )
    return result or 0


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

    # Total students — count enrollments for upcoming occurrences
    total_students = 0
    for s in sessions:
        if s.is_recurring and s.day_of_week:
            next_d = _next_occurrence(s.day_of_week)
            count = await _count_enrolled(s.id, next_d, db)
            total_students += count
        elif not s.is_recurring and s.date and s.date >= today:
            count = await _count_enrolled(s.id, s.date, db)
            total_students += count

    # Active gyms
    gyms_result = await db.execute(
        select(func.count(GymCoachMembership.gymID)).where(
            GymCoachMembership.coachID == coachID
        )
    )
    active_gyms = gyms_result.scalar() or 0

    return {
        "weekly_classes": weekly_classes,
        "total_students": total_students,
        "active_gyms":    active_gyms,
    }


# ── Upcoming Classes (for dashboard) ─────────────────────────────────────────

async def get_upcoming_classes(coachID: int, db: AsyncSession, limit: int = 3) -> list:
    today = date.today()
    day_names = ["monday", "tuesday", "wednesday",
                 "thursday", "friday", "saturday", "sunday"]

    sessions_result = await db.execute(
        select(ClassSession).where(ClassSession.coach_id == coachID)
    )
    sessions = sessions_result.scalars().all()

    upcoming = []
    for s in sessions:
        gym_name = await get_gym_name(s.gymID, db) if s.gymID else None

        if s.is_recurring and s.day_of_week:
            next_d = _next_occurrence(s.day_of_week)
            count = await _count_enrolled(s.id, next_d, db)
            upcoming.append({
                "id":              s.id,
                "title":           s.title,
                "day_of_week":     s.day_of_week,
                "date":            None,
                "start_time":      s.start_time,
                "duration":        s.duration,
                "gym_name":        gym_name,
                "current_clients": count,
                "max_clients":     s.max_clients,
                "sort_date":       next_d,
            })
        elif not s.is_recurring and s.date and s.date >= today:
            count = await _count_enrolled(s.id, s.date, db)
            upcoming.append({
                "id":              s.id,
                "title":           s.title,
                "day_of_week":     s.day_of_week,
                "date":            s.date,
                "start_time":      s.start_time,
                "duration":        s.duration,
                "gym_name":        gym_name,
                "current_clients": count,
                "max_clients":     s.max_clients,
                "sort_date":       s.date,
            })

    upcoming.sort(key=lambda x: (x["sort_date"], x["start_time"]))
    for u in upcoming:
        u.pop("sort_date")
    return upcoming[:limit]


# ── Schedule Stats ────────────────────────────────────────────────────────────

async def get_schedule_stats(coachID: int, db: AsyncSession) -> dict:
    today = date.today()
    day_names = ["monday", "tuesday", "wednesday",
                 "thursday", "friday", "saturday", "sunday"]

    sessions_result = await db.execute(
        select(ClassSession).where(ClassSession.coach_id == coachID)
    )
    sessions = sessions_result.scalars().all()

    days_in_window = set()
    for i in range(7):
        d = today + timedelta(days=i)
        days_in_window.add(day_names[d.weekday()])

    weekly_classes  = 0
    total_students  = 0

    for s in sessions:
        if s.is_recurring and s.day_of_week and s.day_of_week in days_in_window:
            weekly_classes += 1
            next_d = _next_occurrence(s.day_of_week)
            total_students += await _count_enrolled(s.id, next_d, db)
        elif not s.is_recurring and s.date and today <= s.date:
            weekly_classes += 1
            total_students += await _count_enrolled(s.id, s.date, db)

    pending_requests = await db.scalar(
        select(func.count(ClassRequest.id)).where(
            ClassRequest.coach_id == coachID,
            ClassRequest.status == RequestStatus.PENDING,
        )
    ) or 0

    return {
        "weekly_classes":   weekly_classes,
        "total_students":   total_students,
        "pending_requests": pending_requests,
    }


# ── Weekly Schedule ───────────────────────────────────────────────────────────

async def get_weekly_schedule(coachID: int, db: AsyncSession) -> list:
    today = date.today()
    day_names = ["monday", "tuesday", "wednesday",
                 "thursday", "friday", "saturday", "sunday"]

    days_order = []
    for i in range(7):
        d = today + timedelta(days=i)
        days_order.append({
            "date":     d,
            "day_name": day_names[d.weekday()],
            "label":    d.strftime("%a %b %d"),
        })

    sessions_result = await db.execute(
        select(ClassSession).where(ClassSession.coach_id == coachID)
    )
    sessions = sessions_result.scalars().all()

    schedule = {d["date"]: [] for d in days_order}

    for s in sessions:
        gym_name = await get_gym_name(s.gymID, db) if s.gymID else None

        if s.is_recurring and s.day_of_week:
            for d in days_order:
                if d["day_name"] == s.day_of_week.lower():
                    count = await _count_enrolled(s.id, d["date"], db)
                    schedule[d["date"]].append({
                        "id":              s.id,
                        "title":           s.title,
                        "start_time":      str(s.start_time),
                        "duration":        s.duration,
                        "gym_name":        gym_name,
                        "current_clients": count,
                        "max_clients":     s.max_clients,
                    })
        elif not s.is_recurring and s.date and s.date in schedule:
            count = await _count_enrolled(s.id, s.date, db)
            schedule[s.date].append({
                "id":              s.id,
                "title":           s.title,
                "start_time":      str(s.start_time),
                "duration":        s.duration,
                "gym_name":        gym_name,
                "current_clients": count,
                "max_clients":     s.max_clients,
            })

    for d in schedule:
        schedule[d].sort(key=lambda x: x["start_time"])

    return [
        {
            "day":     d["day_name"],
            "label":   d["label"],
            "classes": schedule[d["date"]],
        }
        for d in days_order
    ]


# ── My Classes ────────────────────────────────────────────────────────────────

async def get_my_classes(coachID: int, db: AsyncSession) -> list:
    today = date.today()

    sessions_result = await db.execute(
        select(ClassSession).where(ClassSession.coach_id == coachID)
        .order_by(ClassSession.day_of_week, ClassSession.start_time)
    )
    sessions = sessions_result.scalars().all()

    classes = []
    for s in sessions:
        if not s.is_recurring and s.date and s.date < today:
            continue
        gym_name = await get_gym_name(s.gymID, db) if s.gymID else None
        if s.is_recurring and s.day_of_week:
            next_d = _next_occurrence(s.day_of_week)
            count = await _count_enrolled(s.id, next_d, db)
        else:
            count = await _count_enrolled(s.id, s.date, db) if s.date else 0

        classes.append({
            "id":              s.id,
            "title":           s.title,
            "day_of_week":     s.day_of_week,
            "date":            s.date,
            "start_time":      s.start_time,
            "duration":        s.duration,
            "is_recurring":    s.is_recurring,
            "gym_name":        gym_name,
            "current_clients": count,
            "max_clients":     s.max_clients,
        })
    return classes


# ── Class Requests ────────────────────────────────────────────────────────────

async def get_class_requests(coachID: int, db: AsyncSession) -> list:
    result = await db.execute(
        select(ClassRequest).where(
            ClassRequest.coach_id == coachID
        ).order_by(ClassRequest.created_at.desc())
    )
    requests = result.scalars().all()

    items = []
    for r in requests:
        items.append({
            "id":                 r.id,
            "coach_id":           r.coach_id,
            "gymID":              r.gymID,
            "class_name":         r.class_name,
            "is_recurring":       r.is_recurring,
            "day_of_week":        r.day_of_week,
            "requested_date":     r.requested_date,
            "requested_time":     r.requested_time,
            "duration":           r.duration,
            "max_capacity":       r.max_capacity,
            "reason_for_request": r.reason_for_request,
            "status":             r.status.value,
            "created_at":         r.created_at,
        })
    return items


async def create_class_request(
    coachID: int,
    gymID: int,
    payload: CreateClassRequestPayload,
    db: AsyncSession
) -> dict:
    day_names = ["monday", "tuesday", "wednesday", "thursday",
                 "friday", "saturday", "sunday"]

    day_of_week    = payload.day_of_week
    requested_date = payload.requested_date

    # Auto-compute day_of_week from date for one-time
    if not payload.is_recurring and payload.requested_date:
        day_of_week = day_names[payload.requested_date.weekday()]

    new_request = ClassRequest(
        coach_id=coachID,
        gymID=gymID,
        class_name=payload.class_name,
        is_recurring=payload.is_recurring,
        day_of_week=day_of_week,
        requested_date=requested_date,
        requested_time=payload.requested_time,
        duration=payload.duration,
        max_capacity=payload.max_capacity,
        reason_for_request=payload.reason,
        status=RequestStatus.PENDING,
    )
    db.add(new_request)
    await db.commit()
    await db.refresh(new_request)

    return {
        "message":    "Request submitted successfully",
        "request_id": new_request.id,
    }




