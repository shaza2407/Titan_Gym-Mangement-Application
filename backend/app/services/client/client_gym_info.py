# app/services/client/client_gym_info.py

from datetime import date, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.Gym import Gym
from app.models.announcement import Announcement
from app.services.admin.admin_schedule import get_all_classes, DAY_NAMES
from app.services.client.client_utils import get_client_gym_or_404


async def fetch_client_gym(clientID: int, db: AsyncSession) -> Gym:
    return await get_client_gym_or_404(clientID, db)


async def fetch_gym_announcements(clientID: int, db: AsyncSession) -> list:
    gym = await get_client_gym_or_404(clientID, db)

    result = await db.execute(
        select(Announcement)
        .where(
            Announcement.gymID == gym.gymID,
            Announcement.reciever.in_(["Clients only", "Clients and Coaches"]),
        )
        .order_by(Announcement.created_at.desc())
    )
    return result.scalars().all()


async def fetch_weekly_schedule(clientID: int, db: AsyncSession) -> dict[str, list]:
    gym = await get_client_gym_or_404(clientID, db)

    today = date.today()
    week_start = today - timedelta(days=today.weekday())   # Monday
    week_end = week_start + timedelta(days=6)              # Sunday

    all_classes = await get_all_classes(
        gymID=gym.gymID,
        db=db,
        week_start=week_start,
        week_end=week_end,
    )

    grouped: dict[str, list] = {day: [] for day in DAY_NAMES}
    for cls in all_classes:
        day_key = cls["day_of_week"]
        if day_key in grouped:
            grouped[day_key].append(cls)

    for day in grouped:
        grouped[day].sort(key=lambda c: c["start_time"])

    return grouped