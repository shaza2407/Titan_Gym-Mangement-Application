

from datetime import date

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.client import Client
from app.models.Gym import Gym
from app.models.gym_clients_membership import GymClientMembership
from app.models.client import Client
from sqlalchemy.orm import selectinload

async def get_client_by_user_id(user_id: int, db: AsyncSession, detail: str = "Only clients can perform this action.") -> Client:
    result = await db.execute(
        select(Client).where(Client.userID == user_id)
    )
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=detail,
        )
    return client

async def get_client_or_404(userID: int, db: AsyncSession) -> Client:
    result = await db.execute(select(Client).where(Client.userID == userID))
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")
    return client

async def get_gym_or_404(gymID: int, db: AsyncSession) -> Gym:
    result = await db.execute(select(Gym).where(Gym.gymID == gymID))
    gym = result.scalar_one_or_none()
    if not gym:
        raise HTTPException(status_code=404, detail="Gym not found")
    return gym


async def get_membership(clientID: int, db: AsyncSession) -> GymClientMembership | None:
    result = await db.execute(
        select(GymClientMembership).where(GymClientMembership.clientID == clientID)
    )
    return result.scalar_one_or_none()


async def get_client_gymID(clientID: int, db: AsyncSession) -> int | None:
    result = await db.execute(
        select(GymClientMembership.gymID).where(GymClientMembership.clientID == clientID)
    )
    return result.scalar_one_or_none()

async def get_client_gym_or_404(clientID: int, db: AsyncSession) -> Gym:
    membership_result = await db.execute(
        select(GymClientMembership)
        .where(GymClientMembership.clientID == clientID)
        .order_by(GymClientMembership.joined_at.desc())
    )
    membership = membership_result.scalar_one_or_none()
    if not membership:
        raise HTTPException(status_code=404, detail="No gym membership found for this client.")

    gym_result = await db.execute(select(Gym).where(Gym.gymID == membership.gymID))
    gym = gym_result.scalar_one_or_none()
    if not gym:
        raise HTTPException(status_code=404, detail="Gym not found.")
    return gym

def get_membership_block_reason(membership: GymClientMembership | None) -> str | None:
    if not membership:
        return "not_connected"
    if membership.status == "suspended":
        return "suspended"
    if membership.subscription_end < date.today():
        return "expired"
    return None
