# app/services/admin_schedule.py

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, delete
from datetime import date, timedelta
from app.models.class_session import ClassSession
from app.models.class_request import ClassRequest, RequestStatus
from app.models.class_enrollment import ClassEnrollment
from app.models.coach import Coach
from app.models import User
from app.schemas.schedule_schema import CreateClassRequest, EditClassRequest
from app.models import GymCoachMembership


# ── Helpers ───────────────────────────────────────────────────────────────────

async def _get_coach_name(coach_id: int, db: AsyncSession) -> str | None:
    result = await db.execute(
        select(User.name).join(Coach, Coach.userID == User.userID)
        .where(Coach.coachID == coach_id)
    )
    return result.scalar_one_or_none()


def _next_weekday(day_name: str) -> date:
    days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    today = date.today()
    target = days.index(day_name.lower())
    days_ahead = (target - today.weekday()) % 7
    if days_ahead == 0:
        days_ahead = 7
    return today + timedelta(days=days_ahead)


# ── Stats ─────────────────────────────────────────────────────────────────────

async def get_admin_schedule_stats(gymID: int, db: AsyncSession) -> dict:
    # Total classes
    total_classes = await db.scalar(
        select(func.count(ClassSession.id)).where(ClassSession.gymID == gymID)
    ) or 0

    # Total enrolled
    total_enrolled = await db.scalar(
    select(func.count(ClassEnrollment.id)).join(
        ClassSession, ClassSession.id == ClassEnrollment.session_id
    ).where(ClassSession.gymID == gymID)
) or 0

    # Total coaches with classes
    total_coaches = await db.scalar(
        select(func.count(ClassSession.coach_id.distinct())).where(ClassSession.gymID == gymID)
    ) or 0

    # Pending requests
    pending_requests = await db.scalar(
        select(func.count(ClassRequest.id)).where(
            ClassRequest.gymID == gymID,
            ClassRequest.status == RequestStatus.PENDING
        )
    ) or 0

    return {
        "total_classes":    total_classes,
        "total_enrolled":   total_enrolled,
        "total_coaches":    total_coaches,
        "pending_requests": pending_requests,
    }


# ── Classes ───────────────────────────────────────────────────────────────────

async def get_all_classes(gymID: int, db: AsyncSession) -> list:
    result = await db.execute(
        select(ClassSession).where(ClassSession.gymID == gymID)
        .order_by(ClassSession.day_of_week, ClassSession.start_time)
    )
    sessions = result.scalars().all()

    classes = []
    for s in sessions:
        coach_name = await _get_coach_name(s.coach_id, db)
        classes.append({
            "id":              s.id,
            "title":           s.title,
            "day_of_week":     s.day_of_week,
            "date":            s.date,
            "start_time":      s.start_time,
            "duration":        s.duration,
            "is_recurring":    s.is_recurring,
            "gymID":           s.gymID,
            "coach_id":        s.coach_id,
            "coach_name":      coach_name,
            "current_clients": s.current_clients,
            "max_clients":     s.max_clients,
        })
    return classes


async def create_class(gymID: int, payload: CreateClassRequest, db: AsyncSession) -> ClassSession | None:
    day_names = ["monday", "tuesday", "wednesday", "thursday",
                 "friday", "saturday", "sunday"]

    day_of_week = payload.day_of_week
    class_date  = payload.date

    # For one-time: compute day_of_week from date
    if not payload.is_recurring and payload.date:
        day_of_week = day_names[payload.date.weekday()]

    # Check for coach time conflict
    if payload.is_recurring and day_of_week:
        conflict = await db.execute(
            select(ClassSession).where(
                ClassSession.coach_id == payload.coach_id,
                ClassSession.day_of_week == day_of_week,
                ClassSession.start_time == payload.start_time,
                ClassSession.is_recurring == True,
            )
        )
        if conflict.scalar_one_or_none():
            return None

    elif not payload.is_recurring and class_date:
        conflict = await db.execute(
            select(ClassSession).where(
                ClassSession.coach_id == payload.coach_id,
                ClassSession.date == class_date,
                ClassSession.start_time == payload.start_time,
                ClassSession.is_recurring == False,
            )
        )
        if conflict.scalar_one_or_none():
            return None

    session = ClassSession(
        title=payload.title,
        coach_id=payload.coach_id,
        gymID=gymID,
        day_of_week=day_of_week,  # auto-computed for one-time
        date=class_date,
        start_time=payload.start_time,
        duration=payload.duration,
        is_recurring=payload.is_recurring,
        max_clients=payload.max_clients,
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return session

async def delete_class(session_id: int, gymID: int, db: AsyncSession) -> bool:
    result = await db.execute(
        select(ClassSession).where(
            ClassSession.id == session_id,
            ClassSession.gymID == gymID
        )
    )
    session = result.scalar_one_or_none()

    if not session:
        return False

    # Delete all enrollments for this class
    await db.execute(
        delete(ClassEnrollment).where(
            ClassEnrollment.session_id == session_id
        )
    )

    # Delete the class itself
    await db.delete(session)

    await db.commit()
    return True


# ── Requests ──────────────────────────────────────────────────────────────────

async def get_pending_requests(gymID: int, db: AsyncSession) -> list:
    result = await db.execute(
        select(ClassRequest).where(
            ClassRequest.gymID == gymID,
            ClassRequest.status == RequestStatus.PENDING
        ).order_by(ClassRequest.created_at.desc())
    )
    requests = result.scalars().all()

    items = []
    for r in requests:
        coach_name = await _get_coach_name(r.coach_id, db)
        items.append({
            "id":                 r.id,
            "coach_id":           r.coach_id,
            "coach_name":         coach_name,
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


async def approve_request(request_id: int, gymID: int, db: AsyncSession) -> bool:
    result = await db.execute(
        select(ClassRequest).where(
            ClassRequest.id == request_id,
            ClassRequest.gymID == gymID,
            ClassRequest.status == RequestStatus.PENDING
        )
    )
    req = result.scalar_one_or_none()
    if not req:
        return False

    # Create class session from request
    session = ClassSession(
    title=req.class_name,
    coach_id=req.coach_id,
    gymID=gymID,
    day_of_week=req.day_of_week,
    date=req.requested_date,
    start_time=req.requested_time,
    duration=req.duration,
    is_recurring=req.is_recurring,
    max_clients=req.max_capacity,
    )
    db.add(session)

    req.status = RequestStatus.APPROVED
    await db.commit()
    return True


async def reject_request(request_id: int, gymID: int, db: AsyncSession) -> bool:
    result = await db.execute(
        select(ClassRequest).where(
            ClassRequest.id == request_id,
            ClassRequest.gymID == gymID,
            ClassRequest.status == RequestStatus.PENDING
        )
    )
    req = result.scalar_one_or_none()
    if not req:
        return False

    req.status = RequestStatus.REJECTED
    await db.commit()
    return True


# ── Edit Class ────────────────────────────────────────────────────────────────
async def edit_class(
    session_id: int,
    gymID: int,
    payload: EditClassRequest,
    db: AsyncSession
) -> ClassSession | None:
    day_names = ["monday", "tuesday", "wednesday", "thursday",
                 "friday", "saturday", "sunday"]

    result = await db.execute(
        select(ClassSession).where(
            ClassSession.id == session_id,
            ClassSession.gymID == gymID
        )
    )
    session = result.scalar_one_or_none()
    if not session:
        return None

    if payload.title is not None:
        session.title = payload.title
    if payload.coach_id is not None:
        session.coach_id = payload.coach_id
    if payload.start_time is not None:
        session.start_time = payload.start_time
    if payload.duration is not None:
        session.duration = payload.duration
    if payload.is_recurring is not None:
        session.is_recurring = payload.is_recurring
    if payload.max_clients is not None:
        session.max_clients = payload.max_clients

    # ── Handle day_of_week / date together ──────────────
    if payload.is_recurring == False or (
            payload.is_recurring is None and not session.is_recurring):
        # One-time class — date drives day_of_week
        if payload.date is not None:
            session.date = payload.date
            session.day_of_week = day_names[payload.date.weekday()]  # ← auto-compute
    else:
        # Recurring class — day_of_week only
        if payload.day_of_week is not None:
            session.day_of_week = payload.day_of_week
            session.date = None  # clear date for recurring

    await db.commit()
    await db.refresh(session)
    return session


# ── View Members ──────────────────────────────────────────────────────────────

async def get_class_members(
    session_id: int,
    gymID: int,
    db: AsyncSession,
    class_date: date | None = None,  # ← add this
) -> list:
    result = await db.execute(
        select(ClassSession).where(
            ClassSession.id == session_id,
            ClassSession.gymID == gymID
        )
    )
    session = result.scalar_one_or_none()
    if not session:
        return []

    from app.models.client import Client

    query = select(ClassEnrollment, User, Client).join(
        Client, Client.clientID == ClassEnrollment.clientID
    ).join(
        User, User.userID == Client.userID
    ).where(ClassEnrollment.session_id == session_id)

    # Filter by date if provided
    if class_date:
        query = query.where(ClassEnrollment.class_date == class_date)

    enrollments = await db.execute(query)
    rows = enrollments.all()

    members = []
    for enrollment, user, client in rows:
        members.append({
            "clientID":    client.clientID,
            "name":        user.name,
            "email":       user.email,
            "phone":       user.phone,
            "class_date":  str(enrollment.class_date),
            "enrolled_at": enrollment.enrolled_at,
        })
    return members


async def get_gym_coaches(gymID: int, db: AsyncSession) -> list:
    result = await db.execute(
        select(Coach.coachID, User.name)
        .join(GymCoachMembership, GymCoachMembership.coachID == Coach.coachID)
        .join(User, User.userID == Coach.userID)
        .where(GymCoachMembership.gymID == gymID)
    )
    return [{"coach_id": row[0], "name": row[1]} for row in result.all()]