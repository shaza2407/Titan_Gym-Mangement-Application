# app/routers/admin_announcements.py

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_session
from app.dependencies.auth import require_admin
from app.models.Admin import Admin
from app.models.Gym import Gym
from app.schemas.admin.announcement_schema import CreateAnnouncementRequest, AnnouncementResponse
from app.services.admin.announcement_service import (
    get_announcements,
    create_announcement,
)

router = APIRouter(prefix="/admin/gyms", tags=["Admin Announcements"])


async def verify_admin_gym(admin_id: int, gym_id: int, db: AsyncSession) -> int:
    result = await db.execute(
        select(Gym).where(Gym.gymID == gym_id, Gym.adminID == admin_id)
    )
    if not result.scalar_one_or_none():
        raise HTTPException(403, "Gym not found or not yours")
    return gym_id


# GET /admin/gyms/{gym_id}/announcements
@router.get("/{gym_id}/announcements", response_model=list[AnnouncementResponse])
async def list_announcements(
    gym_id: int,
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    await verify_admin_gym(admin.adminID, gym_id, db)
    return await get_announcements(gym_id, db)


# POST /admin/gyms/{gym_id}/announcements
@router.post("/{gym_id}/announcements", response_model=AnnouncementResponse, status_code=201)
async def create_new_announcement(
    gym_id: int,
    payload: CreateAnnouncementRequest,
    admin: Admin = Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    await verify_admin_gym(admin.adminID, gym_id, db)
    return await create_announcement(gym_id, payload, db)


