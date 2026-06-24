from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_session
from app.models.Gym import Gym
from app.models.User import User
from app.models.Admin import Admin
from app.dependencies.auth import get_current_user
from sqlalchemy import func
from app.schemas.admin.admin_profile import AdminProfileUpdate

router = APIRouter(prefix="/admin", tags=["Admin"])

@router.get("/profile")
async def get_admin_profile(
    db: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),):
    admin_result = await db.execute(
        select(Admin).where(Admin.userID == current_user.userID)
    )
    admin = admin_result.scalars().first()
    if not admin:
        raise HTTPException(403, "Not an admin")

    # Count gyms
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

# update theirand phone number (profile management)
@router.put("/profile")
async def update_admin_profile(
    data: AdminProfileUpdate,
    db: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    admin_result = await db.execute(
        select(Admin).where(Admin.userID == current_user.userID)
    )
    admin = admin_result.scalars().first()
    if not admin:
        raise HTTPException(status_code=403, detail="User is not an admin")

    # Update name and phone
    if data.name:
        current_user.name = data.name
    if data.phone is not None:
        current_user.phone = data.phone

    await db.commit()
    return {"message": "Profile updated successfully"}