from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.models.Gym import Gym
from app.models.User import User
from app.models.Admin import Admin
from app.schemas.admin.admin_profile import AdminProfileUpdate


async def get_profile(db: AsyncSession, current_user: User) -> dict:
    admin_result = await db.execute(
        select(Admin).where(Admin.userID == current_user.userID)
    )
    admin = admin_result.scalars().first()
    if not admin:
        raise HTTPException(403, "Not an admin")

    gym_count = await db.execute(
        select(func.count(Gym.gymID)).where(Gym.adminID == admin.adminID)
    )
    return {
        "adminID":    admin.adminID,
        "userID":     current_user.userID,
        "name":       current_user.name,
        "email":      current_user.email,
        "phone":      current_user.phone,
        "created_at": str(current_user.created_at) if hasattr(current_user, 'created_at') else None,
        "total_gyms": gym_count.scalar(),
    }


async def update_profile(
    db: AsyncSession,
    current_user: User,
    data: AdminProfileUpdate,
) -> dict:
    admin_result = await db.execute(
        select(Admin).where(Admin.userID == current_user.userID)
    )
    admin = admin_result.scalars().first()
    if not admin:
        raise HTTPException(status_code=403, detail="User is not an admin")

    if data.name:
        current_user.name = data.name
    if data.phone is not None:
        current_user.phone = data.phone

    await db.commit()
    return {"message": "Profile updated successfully"}