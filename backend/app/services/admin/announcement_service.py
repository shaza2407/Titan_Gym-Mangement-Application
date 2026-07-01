from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.announcement import Announcement
from app.schemas.admin.announcement_schema import CreateAnnouncementRequest
from app.services.notifications.notification_Utils import notify_gym_clients ,notify_gym_coaches

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
        reciever=payload.reciever,
    )
    db.add(announcement)
    await db.commit()
    await db.refresh(announcement)

    notify_data = {
        "gym_id": str(gym_id),
        "announce_id": str(announcement.announce_id),
    }
    print(payload.reciever)

    if payload.reciever in ('Clients only', 'Clients and Coaches'):  
        await notify_gym_clients(
            db=db, gym_id=gym_id,
            title=payload.title.strip(),
            body=payload.content.strip(),
            type="announcement", data=notify_data,
        )

    if payload.reciever in ('Coaches only', 'Clients and Coaches'): 
        await notify_gym_coaches(
            db=db, gym_id=gym_id,
            title=payload.title.strip(),
            body=payload.content.strip(),
            type="announcement", data=notify_data,
        )

    return announcement