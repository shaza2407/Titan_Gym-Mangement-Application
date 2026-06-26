from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, delete
from sqlalchemy.dialects.postgresql import insert
from app.models.notification import Notification, FcmToken


class NotificationService:

    @staticmethod
    async def get_notifications(user_id: int, db: AsyncSession):
        result = await db.execute(
            select(Notification)
            .where(Notification.user_id == user_id)
            .order_by(Notification.created_at.desc())
        )
        return result.scalars().all()

    @staticmethod
    async def get_unread_count(user_id: int, db: AsyncSession) -> int:
        result = await db.execute(
            select(func.count())
            .select_from(Notification)
            .where(Notification.user_id == user_id)
        )
        return result.scalar()

    @staticmethod
    async def mark_as_read(notification_id: int, db: AsyncSession) -> bool:
        result = await db.execute(
            delete(Notification).where(Notification.id == notification_id)
        )
        await db.commit()
        return result.rowcount > 0

    @staticmethod
    async def mark_all_read(user_id: int, db: AsyncSession):
        await db.execute(
            delete(Notification).where(Notification.user_id == user_id)
        )
        await db.commit()

    @staticmethod
    async def save_fcm_token(user_id: int, token: str, db: AsyncSession):
        stmt = (
            insert(FcmToken)
            .values(user_id=user_id, token=token)
            .on_conflict_do_update(
                index_elements=["user_id"],
                set_={"token": token, "updated_at": func.now()},
            )
        )
        await db.execute(stmt)
        await db.commit()