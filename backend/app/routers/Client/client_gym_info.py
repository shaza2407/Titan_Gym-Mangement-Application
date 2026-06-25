# app/routers/Client/gym_info.py

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from app.database import get_session
from app.dependencies.auth import require_client
from app.schemas.admin.gym import ClientGymResponse
from app.schemas.admin.announcement_schema import AnnouncementResponse
from app.services.client.client_utils import get_client_or_404
from app.services.client.client_gym_info import (
    fetch_client_gym,
    fetch_gym_announcements,
    fetch_weekly_schedule,
)

router = APIRouter(prefix="/client", tags=["Client - Gym"])


@router.get("/gym", response_model=ClientGymResponse)
async def get_my_gym(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client = await get_client_or_404(current_user.userID, db)
    return await fetch_client_gym(client.clientID, db)


@router.get("/gym/announcements", response_model=List[AnnouncementResponse])
async def get_my_gym_announcements(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client = await get_client_or_404(current_user.userID, db)
    return await fetch_gym_announcements(client.clientID, db)


@router.get("/gym/weekly-schedule")
async def get_gym_weekly_schedule(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client = await get_client_or_404(current_user.userID, db)
    return await fetch_weekly_schedule(client.clientID, db)