#done testing
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_session
from app.dependencies.auth import require_admin
from app.models.Admin import Admin
from app.models.Gym import Gym
from app.schemas.admin.announcement_schema import CreateAnnouncementRequest, AnnouncementResponse
from app.services.admin.announcement_service import (get_announcements,create_announcement,)
from app.dependencies.gym_member_managment import get_admin_gym

router = APIRouter(prefix="/admin/gyms", tags=["Admin Announcements"])


# GET /admin/gyms/{gym_id}/announcements
@router.get("/{gym_id}/announcements", response_model=list[AnnouncementResponse])
async def list_announcements(gym_id: int,gym: Gym = Depends(get_admin_gym),  db: AsyncSession = Depends(get_session),):
    return await get_announcements(gym.gymID, db)


# POST /admin/gyms/{gym_id}/announcements
@router.post("/{gym_id}/announcements", response_model=AnnouncementResponse, status_code=201)
async def create_new_announcement(gym_id: int, payload: CreateAnnouncementRequest,gym: Gym = Depends(get_admin_gym),  db: AsyncSession = Depends(get_session),):
    return await create_announcement(gym.gymID, payload, db)


