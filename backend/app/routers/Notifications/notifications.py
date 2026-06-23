from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, update, delete
from app.database import get_session
from app.models import Notification
from app.models import User
from app.models.notification import FcmToken  
from sqlalchemy.dialects.postgresql import insert


router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("/{user_id}")
async def get_notifications(user_id: int, db: AsyncSession = Depends(get_session)):
    result = await db.execute(
        select(Notification)
        .where(Notification.user_id == user_id)
        .order_by(Notification.created_at.desc())
    )
    return result.scalars().all()

@router.get("/{user_id}/unread-count")
async def get_unread_count(user_id: int, db: AsyncSession = Depends(get_session)):
    result = await db.execute(
        select(func.count())
        .select_from(Notification)
        .where(Notification.user_id == user_id)
    )
    count = result.scalar()
    return {"has_unread": count > 0}

@router.patch("/{notification_id}/read")
async def mark_read(notification_id: str, db: AsyncSession = Depends(get_session)):
    result = await db.execute(
        delete(Notification).where(Notification.id == notification_id)
    )
    await db.commit()

    if result.rowcount == 0:
        raise HTTPException(404, "Notification not found.")

    return {"message": "Notification deleted"}


@router.patch("/{user_id}/read-all")
async def mark_all_read(user_id: int, db: AsyncSession = Depends(get_session)):
    await db.execute(
        delete(Notification).where(Notification.user_id == user_id)
    )
    await db.commit()
    return {"message": "All notifications deleted"}


@router.post("/fcm-token")
async def save_fcm_token(
    user_id: int = Query(...),
    token: str = Query(...),
    db: AsyncSession = Depends(get_session),
):
    stmt = insert(FcmToken).values(
        user_id=user_id,
        token=token,
    ).on_conflict_do_update(
        index_elements=["user_id"],
        set_={"token": token, "updated_at": func.now()}
    )
    await db.execute(stmt)
    await db.commit()
    return {"message": "Token saved"}