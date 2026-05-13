from fastapi import Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_session
from app.dependencies.auth import get_current_user
from app.models.User import User
from app.models.Admin import Admin
from app.models.Gym import Gym


async def get_admin_gym(gym_id: int, db: AsyncSession = Depends(get_session), current_user: User = Depends(get_current_user)) -> Gym:
    if current_user.role != "admin":
        raise HTTPException(403, "Admins only")

    admin = (await db.execute(select(Admin).where(Admin.userID == current_user.userID)
                              )).scalar_one_or_none()
    if not admin:
        raise HTTPException(403, "Admin record not found.")

    gym = (await db.execute(select(Gym).where(Gym.gymID == gym_id, Gym.adminID == admin.adminID)
                            )).scalar_one_or_none()
    if not gym:
        raise HTTPException(404, "Gym not found or you don't manage it..")

    return gym