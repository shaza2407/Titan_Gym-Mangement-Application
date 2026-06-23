# app/routers/Client/gym_info.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import date, timedelta
from app.database import get_session
from app.dependencies.auth import require_client
from app.models.client import Client
from app.models.Gym import Gym
from app.models.announcement import Announcement
from app.models.gym_clients_membership import GymClientMembership
from app.schemas.admin.gym import GymResponse
from app.schemas.admin.announcement_schema import AnnouncementResponse
from app.services.admin.admin_schedule import get_all_classes, DAY_NAMES
from typing import List

router = APIRouter(prefix="/client", tags=["Client - Gym"])


# ── Shared Helpers ────────────────────────────────────────────────────────────

async def get_client_or_404(userID: int, db: AsyncSession) -> Client:
    result = await db.execute(select(Client).where(Client.userID == userID))
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(404, "Client not found")
    return client


async def get_client_gym_or_404(clientID: int, db: AsyncSession) -> Gym:
    membership_result = await db.execute(
        select(GymClientMembership)
        .where(GymClientMembership.clientID == clientID)
        .order_by(GymClientMembership.joined_at.desc())
    )
    membership = membership_result.scalar_one_or_none()
    if not membership:
        raise HTTPException(404, "No gym membership found for this client.")

    gym_result = await db.execute(
        select(Gym).where(Gym.gymID == membership.gymID)
    )
    gym = gym_result.scalar_one_or_none()
    if not gym:
        raise HTTPException(404, "Gym not found.")
    return gym


# ── GET /client/gym ───────────────────────────────────────────────────────────

@router.get("/gym", response_model=GymResponse)
async def get_my_gym(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client = await get_client_or_404(current_user.userID, db)
    gym = await get_client_gym_or_404(client.clientID, db)
    return gym


# ── GET /client/gym/announcements ─────────────────────────────────────────────

@router.get("/gym/announcements", response_model=List[AnnouncementResponse])
async def get_my_gym_announcements(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client = await get_client_or_404(current_user.userID, db)
    gym = await get_client_gym_or_404(client.clientID, db)

    result = await db.execute(
        select(Announcement)
        .where(
            Announcement.gymID == gym.gymID,
            Announcement.reciever.in_(["Clients only", "Clients and Coaches"]),
        )
        .order_by(Announcement.created_at.desc())
    )
    return result.scalars().all()


# ── GET /client/gym/weekly-schedule ──────────────────────────────────────────
# Returns all gym classes for this week grouped by day, regardless of enrollment
# Shape: { "monday": [...], "tuesday": [...], ... }

@router.get("/gym/weekly-schedule")
async def get_gym_weekly_schedule(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client = await get_client_or_404(current_user.userID, db)
    gym = await get_client_gym_or_404(client.clientID, db)

    # Compute this week's Monday → Sunday
    today = date.today()
    week_start = today - timedelta(days=today.weekday())       # Monday
    week_end   = week_start + timedelta(days=6)                # Sunday

    # Reuse admin service — returns all classes (recurring + one-time in window)
    all_classes = await get_all_classes(
        gymID=gym.gymID,
        db=db,
        week_start=week_start,
        week_end=week_end,
    )

    # Group by day in Mon→Sun order to match the Flutter weeklySchedule map
    grouped: dict[str, list] = {day: [] for day in DAY_NAMES}
    for cls in all_classes:
        day_key = cls["day_of_week"]
        if day_key in grouped:
            grouped[day_key].append(cls)

    # Sort each day's classes by start_time
    for day in grouped:
        grouped[day].sort(key=lambda c: c["start_time"])

    return grouped