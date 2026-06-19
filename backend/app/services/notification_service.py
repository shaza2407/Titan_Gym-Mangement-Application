import os
import firebase_admin
from firebase_admin import credentials, messaging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.User import User
from app.models.notification import Notification, FcmToken
from app.models.Gym import Gym
from app.models import Admin ,Coach , ClassRequest , GymClientMembership , Client ,GymCoachMembership
import os

if not firebase_admin._apps:
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    cred_path = os.path.join(BASE_DIR, "..", "serviceAccountKey.json")
    cred = credentials.Certificate(cred_path)
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
        data={k: str(v) for k, v in data.items()}, 
        token=fcm.token,
    )

    try:
        messaging.send(message)
    except Exception as e:
        print(f"FCM send failed: {e}")  # to not crash the app if push fails


async def notify_invite(db: AsyncSession, email: str, gym_name: str, role: str, gym_id: int = None, token: str = None):
    user = (await db.execute(select(User).where(User.email == email))).scalar_one_or_none()
    if not user:
        return

    title = f"You've been invited to {gym_name} as a {role}. "
    body = f"Tap to accept or decline."
    data = {
        "gym_name": gym_name,
        "role": role,
        "gym_id": str(gym_id) if gym_id else "",
        "invite_token": token or "",
        "type": f"gym_invite_{role}",
    }

    await save_notification(db, user.userID, title, body, f"gym_invite_{role}", data)
    await send_push_notification(db, user.userID, title, body, data)

async def notify_admin(db: AsyncSession, gym_id: int, title: str, body: str, type: str, data: dict):
    # Get gym to find adminID
    gym = (await db.execute(select(Gym).where(Gym.gymID == gym_id))).scalar_one_or_none()
    if not gym:
        return

    # Get admin user
    admin = (await db.execute(select(Admin).where(Admin.adminID == gym.adminID))).scalar_one_or_none()
    if not admin:
        return

    await save_notification(db, admin.userID, title, body, type, data)
    await send_push_notification(db, admin.userID, title, body, data)


async def notify_Coach_on_class_approval(
    db: AsyncSession,
    request_id: int,
    gym_id: int,
    title: str,
    body: str,
    type: str,
    data: dict,
):
    gym = (await db.execute(select(Gym).where(Gym.gymID == gym_id))).scalar_one_or_none()
    if not gym:
        return

    coach_id = (
        await db.execute(select(ClassRequest.coach_id).where(ClassRequest.id == request_id))
    ).scalar_one_or_none()
    if not coach_id:
        return

    coach = (
        await db.execute(select(Coach).where(Coach.coachID == coach_id))
    ).scalar_one_or_none()
    if not coach:
        return

    await save_notification(db, coach.userID, title, body, type, data)
    await send_push_notification(db, coach.userID, title, body, data)

async def notify_gym_clients(db: AsyncSession, gym_id: int, title: str, body: str, type: str, data: dict):
    # Step 1 — get all active client IDs
    result = await db.execute(
        select(GymClientMembership.clientID).where(
            GymClientMembership.gymID == gym_id,
            GymClientMembership.status == "active",
        )
    )
    client_ids = result.scalars().all()  # ← list of ints, not a result object
    if not client_ids:
        return

    # Step 2 — get all userIDs in one query using in_()
    result = await db.execute(
        select(Client.userID).where(Client.clientID.in_(client_ids))
    )
    user_ids = result.scalars().all()

    for user_id in user_ids:
        await save_notification(db, user_id, title, body, type, data)
        await send_push_notification(db, user_id, title, body, data)



async def notify_gym_coaches(db: AsyncSession, gym_id: int, title: str, body: str, type: str, data: dict):
    # Step 1 — get all active coach IDs
    result = await db.execute(
        select(GymCoachMembership.coachID).where(
            GymCoachMembership.gymID == gym_id,
            GymCoachMembership.status == "active",  # ← fixed: was GymClientMembership
        )
    )
    coach_ids = result.scalars().all()
    if not coach_ids:
        return

    # Step 2 — get all userIDs in one query
    result = await db.execute(
        select(Coach.userID).where(Coach.coachID.in_(coach_ids))
    )
    user_ids = result.scalars().all()

    for user_id in user_ids:
        await save_notification(db, user_id, title, body, type, data)
        await send_push_notification(db, user_id, title, body, data)