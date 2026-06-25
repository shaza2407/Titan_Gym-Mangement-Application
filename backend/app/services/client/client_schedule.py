# app/services/client/client_schedule.py

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import date, timedelta
from app.models.class_session import ClassSession
from app.models.class_enrollment import ClassEnrollment
from app.models.coach import Coach
from app.models import User
from app.services.client.client_shared import get_membership, get_client_gymID  


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
        days_ahead = 7
    return today + timedelta(days=days_ahead)


async def _get_enrollment(
    session_id: int, clientID: int, class_date: date, db: AsyncSession
) -> ClassEnrollment | None:
    result = await db.execute(
        select(ClassEnrollment).where(
            ClassEnrollment.session_id == session_id,
            ClassEnrollment.clientID == clientID,
            ClassEnrollment.class_date == class_date,
        )
    )
    return result.scalar_one_or_none()


async def _count_enrolled(session_id: int, class_date: date, db: AsyncSession) -> int:
    result = await db.scalar(
        select(func.count(ClassEnrollment.id)).where(
            ClassEnrollment.session_id == session_id,
            ClassEnrollment.class_date == class_date,
        )
    )
    return result or 0


async def _build_class_response(
    session: ClassSession,
    clientID: int,
    db: AsyncSession,
    target_date: date | None = None,
) -> dict:
    coach_name = await _get_coach_name(session.coach_id, db)

    if session.is_recurring and session.day_of_week:
        class_date = target_date or _next_occurrence(session.day_of_week)
    else:
        class_date = session.date

    enrolled = await _get_enrollment(session.id, clientID, class_date, db) is not None
    current  = await _count_enrolled(session.id, class_date, db)
    is_full  = current >= session.max_clients

    return {
        "id":              session.id,
        "title":           session.title,
        "coach_name":      coach_name,
        "day_of_week":     session.day_of_week,
        "date":            session.date,
        "start_time":      session.start_time,
        "duration":        session.duration,
        "is_recurring":    session.is_recurring,
        "current_clients": current,
        "max_clients":     session.max_clients,
        "is_enrolled":     enrolled,
        "is_full":         is_full,
        "next_date":       str(class_date) if class_date else None,
    }


# ── Stats ─────────────────────────────────────────────────────────────────────

async def get_client_schedule_stats(clientID: int, db: AsyncSession) -> dict:
    from datetime import datetime
    now = datetime.now()
    today = now.date()
    start_of_month = today.replace(day=1)
    current_time = now.time()

    future_enrollments_result = await db.execute(
        select(ClassEnrollment, ClassSession)
        .join(ClassSession, ClassSession.id == ClassEnrollment.session_id)
        .where(
            ClassEnrollment.clientID == clientID,
            ClassEnrollment.class_date >= today,
        )
    )
    rows = future_enrollments_result.all()

    active_count = 0
    for enrollment, session in rows:
        if enrollment.class_date > today:
            active_count += 1
        elif enrollment.class_date == today:
            if session.start_time > current_time:
                active_count += 1

    past_month_result = await db.scalar(
        select(func.count(ClassEnrollment.id)).where(
            ClassEnrollment.clientID == clientID,
            ClassEnrollment.class_date >= start_of_month,
            ClassEnrollment.class_date < today,
        )
    ) or 0

    return {
        "enrolled":     active_count,
        "upcoming":     past_month_result,
        "minutes_week": 0,
    }


# ── My Classes ────────────────────────────────────────────────────────────────

async def get_my_classes(clientID: int, db: AsyncSession) -> list:
    today = date.today()
    gymID = await get_client_gymID(clientID, db)
    if not gymID:
        return []

    sessions_result = await db.execute(
        select(ClassSession).where(ClassSession.gymID == gymID)
    )
    sessions = sessions_result.scalars().all()

    classes = []
    for s in sessions:
        if s.is_recurring and s.day_of_week:
            next_d = _next_occurrence(s.day_of_week)
            enrolled = await _get_enrollment(s.id, clientID, next_d, db)
            if enrolled:
                classes.append(await _build_class_response(s, clientID, db, next_d))
        elif s.date and s.date >= today:
            enrolled = await _get_enrollment(s.id, clientID, s.date, db)
            if enrolled:
                classes.append(await _build_class_response(s, clientID, db, s.date))

    return classes


# ── Browse ────────────────────────────────────────────────────────────────────

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
        if not s.is_recurring and s.date and s.date < today:
            continue
        classes.append(await _build_class_response(s, clientID, db))
    return classes


# ── Weekly Schedule ───────────────────────────────────────────────────────────

async def get_weekly_schedule(clientID: int, db: AsyncSession) -> list:
    today = date.today()
    day_names = ["monday", "tuesday", "wednesday",
                 "thursday", "friday", "saturday", "sunday"]

    days_order = [
        {
            "date":     today + timedelta(days=i),
            "day_name": day_names[(today + timedelta(days=i)).weekday()],
            "label":    (today + timedelta(days=i)).strftime("%a %b %d"),
        }
        for i in range(7)
    ]

    gymID = await get_client_gymID(clientID, db)
    if not gymID:
        return [{"day": d["day_name"], "label": d["label"], "classes": []}
                for d in days_order]

    sessions_result = await db.execute(
        select(ClassSession).where(ClassSession.gymID == gymID)
    )
    sessions = sessions_result.scalars().all()

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
            for d in days_order:
                if d["day_name"] == s.day_of_week.lower():
                    if await _get_enrollment(s.id, clientID, d["date"], db):
                        schedule[d["date"]].append(entry)
        elif not s.is_recurring and s.date and s.date in schedule:
            if await _get_enrollment(s.id, clientID, s.date, db):
                schedule[s.date].append(entry)

    for d in schedule:
        schedule[d].sort(key=lambda x: x["start_time"])

    return [
        {"day": d["day_name"], "label": d["label"], "classes": schedule[d["date"]]}
        for d in days_order
    ]


# ── Enroll ────────────────────────────────────────────────────────────────────

async def enroll(session_id: int, clientID: int,
                 class_date: date, db: AsyncSession) -> dict:
    membership = await get_membership(clientID, db)
    if not membership:
        return {"error": "You are not connected to a gym"}
    if membership.status == "suspended":
        return {"error": "Your membership is suspended. Contact your gym to restore access."}
    if membership.subscription_end < date.today():
        return {"error": "Your subscription has expired. Please renew to enroll in classes."}

    result = await db.execute(
        select(ClassSession).where(ClassSession.id == session_id)
    )
    session = result.scalar_one_or_none()
    if not session:
        return {"error": "Class not found"}

    if await _get_enrollment(session_id, clientID, class_date, db):
        return {"error": "Already enrolled for this date"}

    current = await _count_enrolled(session_id, class_date, db)
    if current >= session.max_clients:
        return {"error": "Class is full for this date"}

    db.add(ClassEnrollment(
        session_id=session_id,
        clientID=clientID,
        class_date=class_date,
    ))
    await db.commit()

    return {
        "message":    "Enrolled successfully",
        "session_id": session_id,
        "clientID":   clientID,
        "class_date": str(class_date),
        "start_time": session.start_time,
        "title":      session.title,
    }


# ── Unenroll ──────────────────────────────────────────────────────────────────

async def unenroll(session_id: int, clientID: int,
                   class_date: date, db: AsyncSession) -> dict:
    result = await db.execute(
        select(ClassEnrollment).where(
            ClassEnrollment.session_id == session_id,
            ClassEnrollment.clientID == clientID,
            ClassEnrollment.class_date == class_date,
        )
    )
    enrollment = result.scalar_one_or_none()
    if not enrollment:
        return {"error": "Not enrolled for this date"}

    await db.delete(enrollment)
    await db.commit()
    return {"message": "Unenrolled successfully"}