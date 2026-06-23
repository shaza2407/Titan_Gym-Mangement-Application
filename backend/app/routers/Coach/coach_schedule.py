# app/routers/coach_schedule.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select ,delete ,func
from app.models.notification import Notification
from app.database import get_session
from app.dependencies.auth import require_coach
from app.models.coach import Coach
from app.models.class_session import ClassSession
from app.services.notifications.notification_service import notify_gym_clients
from app.schemas.coach.coach_schemas import (
    CoachGymLookUpResponse,
    CoachScheduleStatsResponse,
    CreateClassRequestPayload,
)
from app.services.coach.coach_schedule import (
    get_schedule_stats,
    get_weekly_schedule,
    get_my_classes,
    get_class_requests,
    create_class_request,
    get_coach_gymID,
    remove_class,
    remove_class_request,
    get_coach_gyms_lookup
)
from app.services.notifications.notification_service import notify_admin
from app.models.Gym import Gym

router = APIRouter(prefix="/coach/schedule", tags=["Coach Schedule"])


async def get_coach_or_404(userID: int, db: AsyncSession) -> Coach:
    result = await db.execute(select(Coach).where(Coach.userID == userID))
    coach = result.scalar_one_or_none()
    if not coach:
        raise HTTPException(404, "Coach not found")
    return coach


# GET /coach/schedule/stats
@router.get("/stats", response_model=CoachScheduleStatsResponse)
async def schedule_stats(
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    stats = await get_schedule_stats(coach.coachID, db)
    return CoachScheduleStatsResponse(**stats)


# GET /coach/schedule/weekly
@router.get("/weekly")
async def weekly(
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    return await get_weekly_schedule(coach.coachID, db)


# GET /coach/schedule/my-classes
@router.get("/my-classes")
async def my_classes(
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    return await get_my_classes(coach.coachID, db)



# GET /coach/schedule/requests
@router.get("/requests")
async def class_requests(
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    return await get_class_requests(coach.coachID, db)

# POST /coach/schedule/requests
@router.post("/requests", status_code=201)
async def create_request(
    payload: CreateClassRequestPayload,
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)
    result = await create_class_request(coach.coachID, payload.gym_id, payload, db)
    gym = (await db.execute(
        select(Gym).where(Gym.gymID == payload.gym_id)
    )).scalar_one_or_none()

    gym_name = gym.gymName if gym else "your gym"

    await notify_admin(
        db=db,
        gym_id=payload.gym_id,
        title="new Class Request",
        body=f"A coach has requested a new class at {gym_name}.",
        type="coach_class_request",
        data={
            "gym_id": str(payload.gym_id),
            "coach_id": str(coach.coachID),
            "class_name": payload.class_name if hasattr(payload, 'class_name') else "",
            "request_id": str(result["request_id"]),
        }
    )

    return result



# DELETE /coach/schedule/my-classes/{class_id}
@router.delete("/my-classes/{class_id}")
async def delete_class(
    class_id: int,
    current_user=Depends(require_coach),
    db: AsyncSession = Depends(get_session)
):
    coach = await get_coach_or_404(current_user.userID, db)

    #Fetch the class before deleting to get gymID and title
    class_session = (await db.execute(
        select(ClassSession).where(ClassSession.id == class_id)
    )).scalar_one_or_none()

    if not class_session:
        raise HTTPException(status_code=404, detail="Class not found")

    success = await remove_class(coach.coachID, class_id, db)
    if not success:
        raise HTTPException(status_code=404, detail="Class not found")

    await notify_gym_clients(
        db=db,
        gym_id=class_session.gymID,
        title="Class Cancelled",
        body=f"The {class_session.title} class has been cancelled.",
        type="class_cancelled",
        data={
            "class_id": str(class_id),
            "gym_id": str(class_session.gymID),
            "class_title": class_session.title,
        }
    )

    return {"message": "Class removed successfully"}
# to delete a requested class.
@router.delete("/requests/{request_id}")
async def delete_request(request_id: int,current_user=Depends(require_coach), db: AsyncSession = Depends(get_session)):
    coach = await get_coach_or_404(current_user.userID, db)
    success = await remove_class_request(coach.coachID, request_id, db)
    if not success:
        raise HTTPException(status_code=404, detail="Class request not found")

    #delete notifications of class request after cancelling it
    await db.execute(
    delete(Notification).where(
        Notification.type == "coach_class_request",
        func.json_extract_path_text(Notification.data, "coach_id") == str(coach.coachID),
        func.json_extract_path_text(Notification.data, "request_id") == str(request_id),
    )
)
    await db.commit()
    return {"message": "Request cancelled and deleted successfully"}


#to get gyms for a coach
@router.get("/gyms", response_model=list[CoachGymLookUpResponse])
async def read_coach_gyms(current_user=Depends(require_coach), db: AsyncSession=Depends(get_session)):
    coach = await get_coach_or_404(current_user.userID, db)
    return await get_coach_gyms_lookup(coach.coachID, db)