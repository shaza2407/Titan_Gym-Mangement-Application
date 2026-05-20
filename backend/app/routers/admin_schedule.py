# app/routers/admin_schedule.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_session
from app.dependencies.auth import require_admin
from app.models.Admin import Admin
from app.models.Gym import Gym
from app.schemas.schedule_schema import (
    CreateClassRequest,
    EditClassRequest,
    AdminScheduleStatsResponse,
    ClassSessionResponse,
    ClassRequestResponse,
)
from app.services.admin_schedule import (
    get_admin_schedule_stats,
    get_all_classes,
    create_class,
    edit_class,
    delete_class,
    approve_request,
    reject_request,
    get_pending_requests,
    get_class_members,
)

router = APIRouter(prefix="/admin/schedule", tags=["Admin Schedule"])


async def get_admin_gymID(admin: Admin, db: AsyncSession) -> int:
    result = await db.execute(
        select(Gym).where(Gym.adminID == admin.adminID)
    )
    gym = result.scalar_one_or_none()
    if not gym:
        raise HTTPException(404, "No gym found for this admin")
    return gym.gymID


# GET /admin/schedule/stats
@router.get("/stats", response_model=AdminScheduleStatsResponse)
async def schedule_stats(
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session)
):
    gymID = await get_admin_gymID(admin, db)
    stats = await get_admin_schedule_stats(gymID, db)
    return AdminScheduleStatsResponse(**stats)


# GET /admin/schedule/classes
@router.get("/classes")
async def all_classes(
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session)
):
    gymID = await get_admin_gymID(admin, db)
    return await get_all_classes(gymID, db)


# POST /admin/schedule/classes
@router.post("/classes", status_code=201)
async def create_new_class(
    payload: CreateClassRequest,
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session)
):
    gymID = await get_admin_gymID(admin, db)
    session = await create_class(gymID, payload, db)
    return {"message": "Class created successfully", "id": session.id}


# PUT /admin/schedule/classes/{session_id}
@router.put("/classes/{session_id}")
async def update_class(
    session_id: int,
    payload: EditClassRequest,
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session)
):
    gymID = await get_admin_gymID(admin, db)
    session = await edit_class(session_id, gymID, payload, db)
    if not session:
        raise HTTPException(404, "Class not found")
    return {"message": "Class updated successfully"}


# DELETE /admin/schedule/classes/{session_id}
@router.delete("/classes/{session_id}")
async def remove_class(
    session_id: int,
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session)
):
    gymID = await get_admin_gymID(admin, db)
    success = await delete_class(session_id, gymID, db)
    if not success:
        raise HTTPException(404, "Class not found")
    return {"message": "Class deleted successfully"}


# GET /admin/schedule/classes/{session_id}/members
@router.get("/classes/{session_id}/members")
async def class_members(
    session_id: int,
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session)
):
    gymID = await get_admin_gymID(admin, db)
    members = await get_class_members(session_id, gymID, db)
    return {"members": members}


# GET /admin/schedule/requests
@router.get("/requests")
async def pending_requests(
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session)
):
    gymID = await get_admin_gymID(admin, db)
    return await get_pending_requests(gymID, db)


# POST /admin/schedule/requests/{request_id}/approve
@router.post("/requests/{request_id}/approve")
async def approve_class_request(
    request_id: int,
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session)
):
    gymID = await get_admin_gymID(admin, db)
    success = await approve_request(request_id, gymID, db)
    if not success:
        raise HTTPException(404, "Request not found or already processed")
    return {"message": "Request approved and class created"}


# POST /admin/schedule/requests/{request_id}/reject
@router.post("/requests/{request_id}/reject")
async def reject_class_request(
    request_id: int,
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session)
):
    gymID = await get_admin_gymID(admin, db)
    success = await reject_request(request_id, gymID, db)
    if not success:
        raise HTTPException(404, "Request not found or already processed")
    return {"message": "Request rejected"}