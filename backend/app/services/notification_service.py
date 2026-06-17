import os
import firebase_admin
from firebase_admin import credentials, messaging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.User import User
from app.models.notification import Notification, FcmToken

# Initialize Firebase once
if not firebase_admin._apps:
    cred = credentials.Certificate("backend/app/serviceAccountKey.json")
    firebase_admin.initialize_app(cred)


async def get_user_by_email(db: AsyncSession, email: str) -> User | None:
    result = await db.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()


async def save_notification(db: AsyncSession, user_id: int, title: str, body: str, type: str, data: dict):
    notification = Notification(
        user_id=user_id,
        title=title,
        body=body,
        type=type,
        data=data,
        is_read=False,
    )
    db.add(notification)
    await db.commit()


async def send_push_notification(db: AsyncSession, user_id: int, title: str, body: str, data: dict):
    result = await db.execute(select(FcmToken).where(FcmToken.user_id == user_id))
    fcm = result.scalar_one_or_none()
    if not fcm:
        return

    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data={k: str(v) for k, v in data.items()},  # ✅ all values must be strings
        token=fcm.token,
    )

    try:
        messaging.send(message)
    except Exception as e:
        print(f"FCM send failed: {e}")  # don't crash the app if push fails


async def notify_invite(db: AsyncSession, email: str, gym_name: str, role: str):
    user = await get_user_by_email(db, email)
    if not user:
        return

    title = f"You've been invited to {gym_name}"
    body = f"You have a new invitation to join as a {role}."
    data = {"gym_name": gym_name, "role": role}

    await save_notification(db, user.userID, title, body, f"gym_invite_{role}", data)
    await send_push_notification(db, user.userID, title, body, data)