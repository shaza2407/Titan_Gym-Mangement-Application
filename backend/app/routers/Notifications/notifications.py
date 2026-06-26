from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_session
from app.services.notifications.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("/{user_id}")
async def get_notifications(user_id: int,db: AsyncSession = Depends(get_session),):
    return await NotificationService.get_notifications(user_id, db)


@router.get("/{user_id}/unread-count")
async def get_unread_count( user_id: int,db: AsyncSession = Depends(get_session),):
    count = await NotificationService.get_unread_count(user_id, db)
    return {"has_unread": count > 0}


@router.patch("/{notification_id}/read")
async def mark_read(notification_id: int ,db: AsyncSession = Depends(get_session),):
    deleted = await NotificationService.mark_as_read(notification_id, db)
    if not deleted:
        raise HTTPException(404, "Notification not found.")
    return {"message": "Notification deleted"}


@router.patch("/{user_id}/read-all")
async def mark_all_read(user_id: int,db: AsyncSession = Depends(get_session),):
    await NotificationService.mark_all_read(user_id, db)
    return {"message": "All notifications deleted"}


@router.post("/fcm-token")
async def save_fcm_token(user_id: int = Query(...),token: str  = Query(...),db: AsyncSession = Depends(get_session),):
    await NotificationService.save_fcm_token(user_id, token, db)
    return {"message": "Token saved"}