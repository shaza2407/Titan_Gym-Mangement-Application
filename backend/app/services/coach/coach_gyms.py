from datetime import date
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from app.models.Gym import Gym
from app.models.coach import Coach
from app.models.announcement import Announcement
from app.models.class_session import ClassSession
from app.models.gym_coachs_membership import GymCoachMembership, CoachMembershipStatus
from app.services.coach.coach_schedule import _count_enrolled, _next_occurrence

async def verify_coach_gym(coachID: int, gymID: int, db: AsyncSession) -> int:
    """Verifies that the coach is a member of the specified gym."""
    result = await db.execute(
        select(GymCoachMembership).where(
            GymCoachMembership.coachID == coachID,
            GymCoachMembership.gymID == gymID
        )
    )
    membership = result.scalar_one_or_none()
    if not membership:
        raise HTTPException(status_code=403, detail="You are not a member of this gym")
    return gymID


async def get_coach_active_gyms(user_id: int, db: AsyncSession) -> list:
    # Find the Coach ID
    coach_query = select(Coach).where(Coach.userID == user_id)
    coach_res = await db.execute(coach_query)
    coach = coach_res.scalar_one_or_none()
    
    if not coach:
        return []

    gyms_query = (
        select(Gym.gymID, Gym.gymName, Gym.location, GymCoachMembership.status, GymCoachMembership.coachID)
        .join(GymCoachMembership, Gym.gymID == GymCoachMembership.gymID)
        .join(Coach, Coach.coachID == GymCoachMembership.coachID)
        .where(Coach.userID == user_id) 
        .where(
            or_(GymCoachMembership.status == CoachMembershipStatus.active,
                GymCoachMembership.status.is_(None))
        )
    )
    gyms_result = await db.execute(gyms_query)
    gym_rows = gyms_result.all()
    
    results = []
    for row in gym_rows:
        gym_id = row.gymID

        # fetch all classes for this coach at this gym
        sessions_query = select(ClassSession).where(ClassSession.coach_id == row.coachID, ClassSession.gymID == gym_id)
        sessions_result = await db.execute(sessions_query)
        sessions = sessions_result.scalars().all()

        clients_count = 0
        upcoming_instances = []

        for s in sessions:
            if s.is_recurring:
                # FIX: Fallback to regular date if day_of_week is missing
                if s.day_of_week:
                    next_d = _next_occurrence(s.day_of_week)
                elif s.date and s.date >= date.today():
                    next_d = s.date
                else:
                    continue  # Skip if it is missing both a valid day and a future date                c_count = await _count_enrolled(s.id, next_d, db)
                clients_count += c_count
                upcoming_instances.append({"session": s, "date": next_d, "current_clients": c_count})
                
            elif not s.is_recurring and s.date and s.date >= date.today():
                c_count = await _count_enrolled(s.id, s.date, db)
                clients_count += c_count
                upcoming_instances.append({"session": s, "date": s.date, "current_clients": c_count})

        classes_count = len(upcoming_instances)
        upcoming_instances.sort(key=lambda x: (x["date"], x["session"].start_time))

        next_class_date = None
        if upcoming_instances:
            next_inst = upcoming_instances[0]
            next_session = next_inst["session"]
            next_class_date = {
                "id": next_session.id,
                "title": next_session.title,
                "day_of_week": next_session.day_of_week,
                "date": next_inst["date"],
                "start_time": next_session.start_time,
                "duration": next_session.duration,
                "gym_name": row.gymName,
                "current_clients": next_inst["current_clients"],
                "max_clients": next_session.max_clients
            }
        
        results.append({
            "gym_id": gym_id,
            "name": row.gymName,
            "address": row.location,
            "status": row.status.value.capitalize() if getattr(row, 'status', None) else "Active",
            "clients_count": clients_count,
            "classes_count": classes_count,
            "next_class": next_class_date
        })    

    return results
                
async def get_coach_announcements(user_id: int, db: AsyncSession, gym_id: int | None = None) -> list:
    # 1. Base query for active gyms
    gyms_query = (
        select(Gym.gymID, Gym.gymName)
        .join(GymCoachMembership, Gym.gymID == GymCoachMembership.gymID)
        .join(Coach, Coach.coachID == GymCoachMembership.coachID)
        .where(Coach.userID == user_id)
        .where(or_(GymCoachMembership.status == CoachMembershipStatus.active, GymCoachMembership.status.is_(None)))
    )

    # 2. Apply the gym_id filter if the app asks for a specific gym!
    if gym_id:
        gyms_query = gyms_query.where(Gym.gymID == gym_id)

    gyms_result = await db.execute(gyms_query)
    gym_rows = gyms_result.all()

    results = []

    for row in gym_rows:
        loop_gym_id = row.gymID 

        announcements_query = (
            select(Announcement)
            .where(
                Announcement.gymID == loop_gym_id,
                Announcement.reciever.in_(["Coaches", "Clients and Coaches"])
            )
            .order_by(Announcement.created_at.desc())
        )
        announcements_result = await db.execute(announcements_query)
        announcements = announcements_result.scalars().all()

        for a in announcements:
            results.append({
                "id": a.announce_id,
                "gym_name": row.gymName,
                "title": a.title,
                "content": a.content,
                "created_at": a.created_at.isoformat() if a.created_at else None 
            })
    results.sort(key=lambda x: x["created_at"], reverse=True)

    return results