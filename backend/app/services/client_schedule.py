# app/services/client_schedule.py

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import date, timedelta
from app.models.class_session import ClassSession
from app.models.class_enrollment import ClassEnrollment
from app.models.gym_clients_membership import GymClientMembership
from app.models.coach import Coach
from app.models import User


# ── Helpers ───────────────────────────────────────────────────────────────────

async def _get_coach_name(coach_id: int, db: AsyncSession) -> str | None:
    result = await db.execute(
        select(User.name).join(Coach, Coach.userID == User.userID)
        .where(Coach.coachID == coach_id)
    )
    return result.scalar_one_or_none()


def _next_occurrence(day_name: str) -> date:
    days = ["monday", "tuesday", "wednesday", "thursday",
            "friday", "saturday", "sunday"]
    today = date.today()
    target = days.index(day_name.lower())
    days_ahead = (target - today.weekday()) % 7
    if days_ahead == 0:
        days_ahead = 7  # next week if today is the same day
    return today + timedelta(days=days_ahead)


async def _is_enrolled(session_id: int, clientID: int, db: AsyncSession) -> bool:
    result = await db.execute(
        select(ClassEnrollment).where(
            ClassEnrollment.session_id == session_id,
            ClassEnrollment.clientID == clientID
        )
    )
    return result.scalar_one_or_none() is not None


async def _build_class_response(
    session: ClassSession,
    clientID: int,
    db: AsyncSession
) -> dict:
    coach_name = await _get_coach_name(session.coach_id, db)
    enrolled = await _is_enrolled(session.id, clientID, db)
    next_date = None
    if session.is_recurring and session.day_of_week:
        next_date = _next_occurrence(session.day_of_week)
    elif not session.is_recurring:
        next_date = session.date

    return {
        "id":              session.id,
        "title":           session.title,
        "coach_name":      coach_name,
        "day_of_week":     session.day_of_week,
        "date":            session.date,
        "start_time":      session.start_time,
        "duration":        session.duration,
        "is_recurring":    session.is_recurring,
        "current_clients": session.current_clients,
        "max_clients":     session.max_clients,
        "is_enrolled":     enrolled,
        "is_full":         session.current_clients >= session.max_clients,
        "next_date":       next_date,
    }


# ── Get gym for client ────────────────────────────────────────────────────────

async def get_client_gymID(clientID: int, db: AsyncSession) -> int | None:
    result = await db.execute(
        select(GymClientMembership.gymID).where(
            GymClientMembership.clientID == clientID
        )
    )
    return result.scalar_one_or_none()


# ── Stats ─────────────────────────────────────────────────────────────────────
async def get_client_schedule_stats(clientID: int, db: AsyncSession) -> dict:
    today = date.today()
    start_of_month = today.replace(day=1)

    day_names = ["monday", "tuesday", "wednesday",
                 "thursday", "friday", "saturday", "sunday"]

    enrolled_result = await db.execute(
        select(ClassSession).join(
            ClassEnrollment,
            ClassEnrollment.session_id == ClassSession.id
        ).where(ClassEnrollment.clientID == clientID)
    )
    sessions = enrolled_result.scalars().all()

    active_classes    = 0  # currently enrolled active classes
    attended_month    = 0  # classes that already happened this month

    for s in sessions:
        if s.is_recurring:
            active_classes += 1

            # Count how many times this recurring class happened
            # from start of month until yesterday
            if s.day_of_week:
                check = start_of_month
                while check < today:
                    if day_names[check.weekday()] == s.day_of_week.lower():
                        attended_month += 1
                    check += timedelta(days=1)

        elif s.date:
            if s.date >= today:
                active_classes += 1  # future one-time → still active
            if start_of_month <= s.date < today:
                attended_month += 1  # one-time that already passed this month

    return {
        "enrolled":     active_classes,
        "upcoming":     attended_month,
        "minutes_week": 0,
    }

# ── My Classes ────────────────────────────────────────────────────────────────

async def get_my_classes(clientID: int, db: AsyncSession) -> list:
    today = date.today()
    result = await db.execute(
        select(ClassSession).join(
            ClassEnrollment,
            ClassEnrollment.session_id == ClassSession.id
        ).where(ClassEnrollment.clientID == clientID)
        .order_by(ClassSession.day_of_week, ClassSession.start_time)
    )
    sessions = result.scalars().all()

    classes = []
    for s in sessions:
        # Skip one-time classes that already passed
        if not s.is_recurring and s.date and s.date < today:
            continue
        classes.append(await _build_class_response(s, clientID, db))
    return classes


# ── Upcoming Classes ──────────────────────────────────────────────────────────

async def get_upcoming_classes(clientID: int, db: AsyncSession) -> list:
    gymID = await get_client_gymID(clientID, db)
    if not gymID:
        return []

    today = date.today()
    end = today + timedelta(days=14)
    days_of_week = ["monday", "tuesday", "wednesday",
                    "thursday", "friday", "saturday", "sunday"]
    remaining_days = days_of_week[today.weekday():]

    result = await db.execute(
        select(ClassSession).join(
            ClassEnrollment,
            ClassEnrollment.session_id == ClassSession.id
        ).where(
            ClassEnrollment.clientID == clientID,
            ClassSession.gymID == gymID
        )
    )
    sessions = result.scalars().all()

    upcoming = []
    for s in sessions:
        if s.is_recurring and s.day_of_week:
            # Add next occurrence
            next_d = _next_occurrence(s.day_of_week)
            item = await _build_class_response(s, clientID, db)
            item["next_date"] = next_d
            upcoming.append(item)
        elif not s.is_recurring and s.date and today <= s.date <= end:
            upcoming.append(await _build_class_response(s, clientID, db))

    upcoming.sort(key=lambda x: x["next_date"] or date.max)
    return upcoming


# ── Browse All Classes ────────────────────────────────────────────────────────

async def browse_classes(
    clientID: int,
    db: AsyncSession,
    day_filter: str | None = None
) -> list:
    gymID = await get_client_gymID(clientID, db)
    if not gymID:
        return []

    today = date.today()
    query = select(ClassSession).where(ClassSession.gymID == gymID)
    
    if day_filter:
        query = query.where(ClassSession.day_of_week == day_filter.lower())

    result = await db.execute(
        query.order_by(ClassSession.day_of_week, ClassSession.start_time)
    )
    sessions = result.scalars().all()

    classes = []
    for s in sessions:
        # Skip one-time classes that already passed
        if not s.is_recurring and s.date and s.date < today:
            continue
        classes.append(await _build_class_response(s, clientID, db))
    return classes


# ── Weekly Schedule ───────────────────────────────────────────────────────────
async def get_weekly_schedule(clientID: int, db: AsyncSession) -> list:
    today = date.today()
    day_names = ["monday", "tuesday", "wednesday",
                 "thursday", "friday", "saturday", "sunday"]

    # Build 7 days starting from today
    days_order = []
    for i in range(7):
        d = today + timedelta(days=i)
        days_order.append({
            "date":     d,
            "day_name": day_names[d.weekday()],
            "label":    d.strftime("%a %b %d"),
        })

    result = await db.execute(
        select(ClassSession).join(
            ClassEnrollment,
            ClassEnrollment.session_id == ClassSession.id
        ).where(ClassEnrollment.clientID == clientID)
    )
    sessions = result.scalars().all()

    # Build schedule keyed by date string for exact matching
    schedule = {d["date"]: [] for d in days_order}

    for s in sessions:
        coach_name = await _get_coach_name(s.coach_id, db)
        entry = {
            "id":         s.id,
            "title":      s.title,
            "start_time": str(s.start_time),
            "duration":   s.duration,
            "coach_name": coach_name,
        }
        if s.is_recurring and s.day_of_week:
            # Find which dates in our 7-day window match this day_of_week
            for d in days_order:
                if d["day_name"] == s.day_of_week.lower():
                    schedule[d["date"]].append(entry)
        elif not s.is_recurring and s.date:
            if s.date in schedule:
                schedule[s.date].append(entry)

    # Sort each day by start_time
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

# ── Enroll ────────────────────────────────────────────────────────────────────

async def enroll(session_id: int, clientID: int, db: AsyncSession) -> dict:
    # Check session exists
    result = await db.execute(
        select(ClassSession).where(ClassSession.id == session_id)
    )
    session = result.scalar_one_or_none()
    if not session:
        return {"error": "Class not found"}

    # Check already enrolled
    if await _is_enrolled(session_id, clientID, db):
        return {"error": "Already enrolled"}

    # Check capacity
    if session.current_clients >= session.max_clients:
        return {"error": "Class is full"}

    # Enroll
    enrollment = ClassEnrollment(
        session_id=session_id,
        clientID=clientID
    )
    db.add(enrollment)
    session.current_clients += 1
    await db.commit()

    return {
        "message":    "Enrolled successfully",
        "session_id": session_id,
        "clientID":   clientID,
    }


# ── Unenroll ──────────────────────────────────────────────────────────────────

async def unenroll(session_id: int, clientID: int, db: AsyncSession) -> dict:
    result = await db.execute(
        select(ClassEnrollment).where(
            ClassEnrollment.session_id == session_id,
            ClassEnrollment.clientID == clientID
        )
    )
    enrollment = result.scalar_one_or_none()
    if not enrollment:
        return {"error": "Not enrolled"}

    # Update count
    sess_result = await db.execute(
        select(ClassSession).where(ClassSession.id == session_id)
    )
    session = sess_result.scalar_one_or_none()
    if session and session.current_clients > 0:
        session.current_clients -= 1

    await db.delete(enrollment)
    await db.commit()

    return {"message": "Unenrolled successfully"}