# app/routers/admin_schedule.py

from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_session
from app.dependencies.auth import require_admin
from app.services.notifications.notification_service import notify_gym_clients
from app.models.Admin import Admin
from app.models.class_session import ClassSession
from app.models.Gym import Gym
from app.schemas.shared.schedule_schema import (
    CreateClassRequest,
    EditClassRequest,
    AdminScheduleStatsResponse,
)
from app.services.admin.admin_schedule import (
    get_admin_schedule_stats,
    get_all_classes,
    create_class,
    edit_class,
    delete_class,
    approve_request,
    reject_request,
    get_pending_requests,
    get_class_members,
    get_gym_coaches,
)
from app.services.notifications.notification_service import notify_Coach_on_class_approval

router = APIRouter(prefix="/admin/schedule", tags=["Admin Schedule"])


async def verify_admin_gym(adminID: int, gymID: int, db: AsyncSession) -> int:
    result = await db.execute(
        select(Gym).where(Gym.gymID == gymID, Gym.adminID == adminID)
    )
    gym = result.scalar_one_or_none()
    if not gym:
        raise HTTPException(403, "Gym not found or not yours")
    return gymID


# GET /admin/schedule/stats?gym_id=1
@router.get("/stats", response_model=AdminScheduleStatsResponse)
async def schedule_stats(
    gym_id: int = Query(...),
    week_only: bool = Query(False),        
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    gymID = await verify_admin_gym(admin.adminID, gym_id, db)
    stats = await get_admin_schedule_stats(gymID, db, week_only=week_only)
    return AdminScheduleStatsResponse(**stats)


# GET /admin/schedule/coaches?gym_id=1
@router.get("/coaches")
async def gym_coaches(
    gym_id: int = Query(...),
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    gymID = await verify_admin_gym(admin.adminID, gym_id, db)
    return await get_gym_coaches(gymID, db)


# GET /admin/schedule/classes?gym_id=1
@router.get("/classes")
async def all_classes(
    gym_id: int = Query(...),
    from_date: date | None = Query(None),
    week_start: date | None = Query(None),   # <-- add
    week_end: date | None = Query(None),     # <-- add
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    gymID = await verify_admin_gym(admin.adminID, gym_id, db)
    return await get_all_classes(gymID, db, from_date=from_date, week_start=week_start, week_end=week_end)


# POST /admin/schedule/classes?gym_id=1
@router.post("/classes", status_code=201)
async def create_new_class(
    payload: CreateClassRequest,
    gym_id: int = Query(...),
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    gymID = await verify_admin_gym(admin.adminID, gym_id, db)
    session, error = await create_class(gymID, payload, db)
    if error:
        raise HTTPException(409, error)
    return {"message": "Class created successfully", "id": session.id}


# PUT /admin/schedule/classes/{session_id}?gym_id=1
@router.put("/classes/{session_id}")
async def update_class(
    session_id: int,
    payload: EditClassRequest,
    gym_id: int = Query(...),
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    gymID = await verify_admin_gym(admin.adminID, gym_id, db)
    session, error = await edit_class(session_id, gymID, payload, db)
    if error:
        status_code = 404 if "not found" in error.lower() else 409
        raise HTTPException(status_code, error)
    return {"message": "Class updated successfully"}


# DELETE /admin/schedule/classes/{session_id}?gym_id=1
@router.delete("/classes/{session_id}")
async def remove_class(
    session_id: int,
    gym_id: int = Query(...),
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    gymID = await verify_admin_gym(admin.adminID, gym_id, db)

    # Fetch before deleting
    class_session = (await db.execute(
        select(ClassSession).where(ClassSession.id == session_id)
    )).scalar_one_or_none()

    if not class_session:
        raise HTTPException(404, "Class not found")

    success = await delete_class(session_id, gymID, db)
    if not success:
        raise HTTPException(404, "Class not found")

    await notify_gym_clients(
        db=db,
        gym_id=gymID,
        title="Class Cancelled",
        body=f"The {class_session.title} class has been cancelled.",
        type="class_cancelled",
        data={
            "class_id": str(session_id),
            "gym_id": str(gymID),
            "class_title": class_session.title,
        }
    )
    return {"message": "Class deleted successfully"}


# GET /admin/schedule/classes/{session_id}/members?gym_id=1
@router.get("/classes/{session_id}/members")
async def class_members(
    session_id: int,
    class_date: date | None = None,
    gym_id: int = Query(...),
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    gymID = await verify_admin_gym(admin.adminID, gym_id, db)
    members = await get_class_members(session_id, gymID, db, class_date)
    return {"members": members}


# GET /admin/schedule/requests?gym_id=1
@router.get("/requests")
async def pending_requests(
    gym_id: int = Query(...),
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    gymID = await verify_admin_gym(admin.adminID, gym_id, db)
    return await get_pending_requests(gymID, db)


# POST /admin/schedule/requests/{request_id}/approve?gym_id=1
@router.post("/requests/{request_id}/approve")
async def approve_class_request(
    request_id: int,
    gym_id: int = Query(...),
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    gymID = await verify_admin_gym(admin.adminID, gym_id, db)
    success, error = await approve_request(request_id, gymID, db)
    if not success:
        status_code = 404 if "not found" in (error or "").lower() else 409
        raise HTTPException(status_code, error)

    gym_name = (await db.execute(select(Gym.gymName).where(Gym.gymID == gym_id))).scalar_one_or_none()
    await notify_Coach_on_class_approval(
        db=db,
        request_id=request_id,
        gym_id=gymID,
        title="Admin Approval",
        body=f"Admin approved your class request at {gym_name}",
        type="admin class permission",
        data={
            "gym_id": str(gym_id),
            "request_id": str(request_id),
        },
    )
    return {"message": "Request approved and class created"}


# POST /admin/schedule/requests/{request_id}/reject?gym_id=1
@router.post("/requests/{request_id}/reject")
async def reject_class_request(
    request_id: int,
    gym_id: int = Query(...),
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    gymID = await verify_admin_gym(admin.adminID, gym_id, db)
    success = await reject_request(request_id, gymID, db)
    if not success:
        raise HTTPException(404, "Request not found or already processed")

    gym_name = (await db.execute(select(Gym.gymName).where(Gym.gymID == gym_id))).scalar_one_or_none()

    await notify_Coach_on_class_approval(
        db=db,
        request_id=request_id,
        gym_id=gymID,
        title="Admin Rejection",
        body=f"Admin Rejected on class request of {gym_name} gym",
        type="admin class permission",
        data={
            "gym_id": str(gym_id),
            "request_id": str(request_id),
        },
    )

    return {"message": "Request rejected"}