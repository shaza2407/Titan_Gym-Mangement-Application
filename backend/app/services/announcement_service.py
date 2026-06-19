# app/services/announcement_service.py

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.Announcement import Announcement
from app.schemas.announcement_schema import CreateAnnouncementRequest
from app.services.notification_service import notify_gym_clients ,notify_gym_coaches

async def get_announcements(gym_id: int, db: AsyncSession) -> list[Announcement]:
    result = await db.execute(
        select(Announcement)
        .where(Announcement.gymID == gym_id)
        .order_by(Announcement.created_at.desc())
    )
    return result.scalars().all()


async def create_announcement(
    gym_id: int, payload: CreateAnnouncementRequest, db: AsyncSession
) -> Announcement:
    announcement = Announcement(
        gymID=gym_id,
        title=payload.title.strip(),
        content=payload.content.strip(),
    )
    db.add(announcement)
    await db.commit()
    await db.refresh(announcement)

    # Notify all active gym members
    await notify_gym_clients(
        db=db,
        gym_id=gym_id,
        title=payload.title.strip(),
        body=payload.content.strip(),
        type="announcement",
        data={
            "gym_id": str(gym_id),
            "announce_id": str(announcement.announce_id),
        },
    )
    await notify_gym_coaches(
        db=db,
        gym_id=gym_id,
        title=payload.title.strip(),
        body=payload.content.strip(),
        type="announcement",
        data={
            "gym_id": str(gym_id),
            "announce_id": str(announcement.announce_id),
        },
    )

    return announcement

