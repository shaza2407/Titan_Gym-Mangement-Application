from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.notification import FcmToken
from app.models import User
from app.models.client import Client
from app.services.notification_service import send_push_notification ,save_notification
from app.database import get_session


async def notify_class_reminder(session_id: int, client_id: int, class_title: str):
    async for db in get_session():
        client = (await db.execute(
            select(Client).where(Client.clientID == client_id)
        )).scalar_one_or_none()

        if not client:
            return

        await save_notification(db=db,
            user_id=client.userID,
            title="Class Reminder 🏋️",
            body=f"Your {class_title} class is today! Don't forget to show up.",
            type="class-reminder",
            data={"session_id": str(session_id)})
        
        await send_push_notification(
            db=db,
            user_id=client.userID,
            title="Class Reminder 🏋️",
            body=f"Your {class_title} class is today! Don't forget to show up.",
            data={"session_id": str(session_id)}
        )
