# app/services/admin_schedule.py

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, delete, and_, or_
from datetime import date, timedelta
from app.models.class_session import ClassSession
from app.models.class_request import ClassRequest, RequestStatus
from app.models.class_enrollment import ClassEnrollment
from app.models.coach import Coach
from app.models import User
from app.schemas.schedule_schema import CreateClassRequest, EditClassRequest
from app.models import GymCoachMembership
from datetime import date, timedelta, datetime


# ── Helpers ───────────────────────────────────────────────────────────────────
DAY_NAMES = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

def _is_passed_today(s, today: date, today_weekday: str) -> bool:
    is_today = s.day_of_week == today_weekday if s.is_recurring else s.date == today
    if not is_today:
        return False
    return _is_past_datetime(today, s.start_time)
    
def _is_past_datetime(class_date: date, start_time) -> bool:
    from datetime import time as dt_time
    if isinstance(start_time, dt_time):
        t = start_time
    else:
        parts = start_time.split(':')
        t = dt_time(int(parts[0]), int(parts[1]))
    class_dt = datetime.combine(class_date, t)
    return class_dt < datetime.now()

async def _get_coach_name(coach_id: int, db: AsyncSession) -> str | None:
    result = await db.execute(
        select(User.name).join(Coach, Coach.userID == User.userID)
        .where(Coach.coachID == coach_id)
    )
    return result.scalar_one_or_none()

async def _count_enrolled_for_session(
    session_id: int,
    is_recurring: bool,
    class_date: date | None,
    db: AsyncSession,
) -> int:
    if is_recurring:
        # Count upcoming enrollments (today onwards) for this recurring session
        result = await db.scalar(
            select(func.count(ClassEnrollment.id)).where(
                ClassEnrollment.session_id == session_id,
                ClassEnrollment.class_date >= date.today(),
            )
        )
    else:
        result = await db.scalar(
            select(func.count(ClassEnrollment.id)).where(
                ClassEnrollment.session_id == session_id,
                ClassEnrollment.class_date == class_date,
            )
        )
    return result or 0

def _next_weekday(day_name: str) -> date:
    days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    today = date.today()
    target = days.index(day_name.lower())
    days_ahead = (target - today.weekday()) % 7
    if days_ahead == 0:
        days_ahead = 7
    return today + timedelta(days=days_ahead)


async def _coach_belongs_to_gym(coach_id: int, gym_id: int, db: AsyncSession) -> bool:
   
    result = await db.execute(
        select(GymCoachMembership).where(
            GymCoachMembership.coachID == coach_id,
            GymCoachMembership.gymID == gym_id,
        )
    )
    return result.scalar_one_or_none() is not None


async def _coach_has_conflict(
    coach_id: int,
    is_recurring: bool,
    day_of_week: str | None,
    class_date: date | None,
    start_time: str,
    db: AsyncSession,
    exclude_session_id: int | None = None,
) -> bool:
    filters = [ClassSession.coach_id == coach_id, ClassSession.start_time == start_time]
    if exclude_session_id is not None:
        filters.append(ClassSession.id != exclude_session_id)

    if is_recurring and day_of_week:
        filters.append(ClassSession.day_of_week == day_of_week)
        filters.append(ClassSession.is_recurring == True)
    elif not is_recurring and class_date:
        filters.append(ClassSession.date == class_date)
        filters.append(ClassSession.is_recurring == False)
    else:
        return False

    result = await db.execute(select(ClassSession).where(and_(*filters)))
    return result.scalar_one_or_none() is not None


async def _gym_slot_conflict(
    gym_id: int,
    is_recurring: bool,
    day_of_week: str | None,
    class_date: date | None,
    start_time: str,
    db: AsyncSession,
    exclude_session_id: int | None = None,
) -> bool:
    
    filters = [ClassSession.gymID == gym_id, ClassSession.start_time == start_time]
    if exclude_session_id is not None:
        filters.append(ClassSession.id != exclude_session_id)

    if is_recurring and day_of_week:
        filters.append(ClassSession.day_of_week == day_of_week)
        filters.append(ClassSession.is_recurring == True)
    elif not is_recurring and class_date:
        filters.append(ClassSession.date == class_date)
        filters.append(ClassSession.is_recurring == False)
    else:
        return False

    result = await db.execute(select(ClassSession).where(and_(*filters)))
    return result.scalar_one_or_none() is not None


# ── Stats ─────────────────────────────────────────────────────────────────────

async def get_admin_schedule_stats(gymID: int, db: AsyncSession, week_only: bool = False) -> dict:
    today = date.today()
    today_weekday = DAY_NAMES[today.weekday()]

    result = await db.execute(select(ClassSession).where(ClassSession.gymID == gymID))
    all_sessions = result.scalars().all()

    upcoming_sessions = [
        s for s in all_sessions
        if (s.is_recurring or s.date is None or s.date >= today)
        and not _is_passed_today(s, today, today_weekday)
    ]

    total_classes = len(upcoming_sessions)
    total_coaches = len({s.coach_id for s in upcoming_sessions})

    enroll_result = await db.execute(
        select(ClassEnrollment, ClassSession)
        .join(ClassSession, ClassSession.id == ClassEnrollment.session_id)
        .where(
            ClassSession.gymID == gymID,
            ClassEnrollment.class_date >= today,
        )
    )
    total_enrolled = sum(
        1 for enrollment, s in enroll_result.all()
        if not (enrollment.class_date == today and _is_past_datetime(today, s.start_time))
    )

    pending_requests = await db.scalar(
        select(func.count(ClassRequest.id)).where(
            ClassRequest.gymID == gymID,
            ClassRequest.status == RequestStatus.PENDING,
        )
    ) or 0

    return {
        "total_classes":    total_classes,
        "total_enrolled":   total_enrolled,
        "total_coaches":    total_coaches,
        "pending_requests": pending_requests,
    }

async def get_all_classes(
    gymID: int,
    db: AsyncSession,
    from_date: date | None = None,
    week_start: date | None = None,
    week_end: date | None = None,
) -> list:
    filters = [ClassSession.gymID == gymID]

    if week_start and week_end:
        filters.append(
            or_(
                ClassSession.is_recurring == True,
                and_(
                    or_(ClassSession.is_recurring == False, ClassSession.is_recurring.is_(None)),
                    ClassSession.date >= week_start,
                    ClassSession.date <= week_end,
                )
            )
        )
    elif from_date:
        filters.append(
            or_(
                ClassSession.is_recurring == True,
                and_(
                    ClassSession.is_recurring == False,
                    ClassSession.date >= from_date,
                )
            )
        )

    result = await db.execute(
        select(ClassSession).where(and_(*filters))
        .order_by(ClassSession.day_of_week, ClassSession.start_time)
    )
    sessions = result.scalars().all()

    classes = []
    for s in sessions:
        coach_name = await _get_coach_name(s.coach_id, db)
        current_clients = await _count_enrolled_for_session(
            s.id, s.is_recurring, s.date, db
        )

        day_name = s.day_of_week
        if s.is_recurring and not day_name and s.date:
            try:
                day_name = s.date.strftime("%A").lower() 
            except AttributeError:
                pass
        
        classes.append({
            "id":              s.id,
            "title":           s.title,
            "day_of_week":     day_name,
            "date":            s.date,
            "start_time":      s.start_time,
            "duration":        s.duration,
            "is_recurring":    True if s.is_recurring else False,
            "gymID":           s.gymID,
            "coach_id":        s.coach_id,
            "coach_name":      coach_name,
            "current_clients": current_clients,
            "max_clients":     s.max_clients,
        })
    return classes



# Return value is now a dict so the router can surface the specific error reason.
async def create_class(
    gymID: int, payload: CreateClassRequest, db: AsyncSession
) -> tuple[ClassSession | None, str | None]:
    
    day_names = ["monday", "tuesday", "wednesday", "thursday",
                 "friday", "saturday", "sunday"]

    day_of_week = payload.day_of_week
    class_date  = payload.date

    # One-time classes must be today or in the future
    if not payload.is_recurring:
        if not payload.date:
            return None, "Date is required for one-time classes"
        if _is_past_datetime(payload.date, payload.start_time):
            return None, "Class date and time must be in the future"

    # For one-time: derive day_of_week from date
    if not payload.is_recurring and payload.date:
        day_of_week = day_names[payload.date.weekday()]

    # 1. Verify coach belongs to this gym
    if not await _coach_belongs_to_gym(payload.coach_id, gymID, db):
        return None, "Coach is not a member of this gym"

    # 2. Coach time-slot conflict
    if await _coach_has_conflict(
        coach_id=payload.coach_id,
        is_recurring=payload.is_recurring,
        day_of_week=day_of_week,
        class_date=class_date,
        start_time=payload.start_time,
        db=db,
    ):
        return None, "Coach already has a class at this time"

    # 3. Gym-wide slot conflict (same gym, same day+time)
    if await _gym_slot_conflict(
        gym_id=gymID,
        is_recurring=payload.is_recurring,
        day_of_week=day_of_week,
        class_date=class_date,
        start_time=payload.start_time,
        db=db,
    ):
        return None, "Another class is already scheduled at this time slot"

    session = ClassSession(
        title=payload.title,
        coach_id=payload.coach_id,
        gymID=gymID,
        day_of_week=day_of_week,
        date=class_date,
        start_time=payload.start_time,
        duration=payload.duration,
        is_recurring=payload.is_recurring,
        max_clients=payload.max_clients,
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return session, None


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

    await db.execute(
        delete(ClassEnrollment).where(ClassEnrollment.session_id == session_id)
    )
    await db.delete(session)
    await db.commit()
    return True


# ── Edit Class ────────────────────────────────────────────────────────────────

async def edit_class(
    session_id: int,
    gymID: int,
    payload: EditClassRequest,
    db: AsyncSession,
) -> tuple[ClassSession | None, str | None]:
    """
    Returns (session, None) on success.
    Returns (None, error_message) on conflict or not-found.
    """
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
        return None, "Class not found"

    # Resolve effective values (merge payload over current state)
    effective_is_recurring = payload.is_recurring if payload.is_recurring is not None else session.is_recurring
    effective_coach_id     = payload.coach_id     if payload.coach_id     is not None else session.coach_id
    effective_start_time   = payload.start_time   if payload.start_time   is not None else session.start_time

    if not effective_is_recurring:
        effective_date = payload.date if payload.date is not None else session.date
        effective_day  = day_names[effective_date.weekday()] if effective_date else session.day_of_week

        if effective_date and _is_past_datetime(effective_date, effective_start_time):
            return None, "Class date and time must be in the future"
    else:
        effective_date = None
        effective_day  = payload.day_of_week if payload.day_of_week is not None else session.day_of_week

    # 1. Verify new coach (if changing) belongs to this gym
    if payload.coach_id is not None and payload.coach_id != session.coach_id:
        if not await _coach_belongs_to_gym(payload.coach_id, gymID, db):
            return None, "Coach is not a member of this gym"

    # 2. Coach time-slot conflict (exclude self)
    if await _coach_has_conflict(
        coach_id=effective_coach_id,
        is_recurring=effective_is_recurring,
        day_of_week=effective_day,
        class_date=effective_date,
        start_time=effective_start_time,
        db=db,
        exclude_session_id=session_id,
    ):
        return None, "Coach already has a class at this time"

    # 3. Gym-wide slot conflict (exclude self)
    if await _gym_slot_conflict(
        gym_id=gymID,
        is_recurring=effective_is_recurring,
        day_of_week=effective_day,
        class_date=effective_date,
        start_time=effective_start_time,
        db=db,
        exclude_session_id=session_id,
    ):
        return None, "Another class is already scheduled at this time slot"

    # Apply updates
    if payload.title       is not None: session.title       = payload.title
    if payload.coach_id    is not None: session.coach_id    = payload.coach_id
    if payload.start_time  is not None: session.start_time  = payload.start_time
    if payload.duration    is not None: session.duration    = payload.duration
    if payload.is_recurring is not None: session.is_recurring = payload.is_recurring
    if payload.max_clients is not None: session.max_clients = payload.max_clients

    if not effective_is_recurring:
        if payload.date is not None:
            session.date        = payload.date
            session.day_of_week = day_names[payload.date.weekday()]
    else:
        if payload.day_of_week is not None:
            session.day_of_week = payload.day_of_week
        session.date = None  # clear date for recurring

    await db.commit()
    await db.refresh(session)
    return session, None


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


async def approve_request(
    request_id: int, gymID: int, db: AsyncSession
) -> tuple[bool, str | None]:
    """
    Returns (True, None) on success.
    Returns (False, error_message) on conflict or not-found.
    """
    result = await db.execute(
        select(ClassRequest).where(
            ClassRequest.id == request_id,
            ClassRequest.gymID == gymID,
            ClassRequest.status == RequestStatus.PENDING
        )
    )
    req = result.scalar_one_or_none()
    if not req:
        return False, "Request not found or already processed"

    day_names = ["monday", "tuesday", "wednesday", "thursday",
                 "friday", "saturday", "sunday"]

    effective_day = req.day_of_week
    if not req.is_recurring and req.requested_date:
        effective_day = day_names[req.requested_date.weekday()]

    if not req.is_recurring and req.requested_date:
        if _is_past_datetime(req.requested_date, req.requested_time):
            return False, "Cannot approve: class date and time has already passed"
    
    # Coach conflict check before creating the class
    if await _coach_has_conflict(
        coach_id=req.coach_id,
        is_recurring=req.is_recurring,
        day_of_week=effective_day,
        class_date=req.requested_date,
        start_time=req.requested_time,
        db=db,
    ):
        return False, "Coach already has a class at this time"

    if await _gym_slot_conflict(
        gym_id=gymID,
        is_recurring=req.is_recurring,
        day_of_week=effective_day,
        class_date=req.requested_date,
        start_time=req.requested_time,
        db=db,
    ):
        return False, "Another class is already scheduled at this time slot"

    session = ClassSession(
        title=req.class_name,
        coach_id=req.coach_id,
        gymID=gymID,
        day_of_week=effective_day,
        date=req.requested_date,
        start_time=req.requested_time,
        duration=req.duration,
        is_recurring=req.is_recurring,
        max_clients=req.max_capacity,
    )
    db.add(session)
    req.status = RequestStatus.APPROVED
    await db.commit()
    return True, None


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


# ── View Members ──────────────────────────────────────────────────────────────

async def get_class_members(
    session_id: int,
    gymID: int,
    db: AsyncSession,
    class_date: date | None = None,
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