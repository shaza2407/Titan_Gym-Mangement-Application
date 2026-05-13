from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException, status

from app.models.Gym import Gym
from app.schemas.gym import GymCreate, GymUpdate


async def get_gym_by_admin(db: AsyncSession, gym_id: int, admin_id: int) -> Gym:
    result = await db.execute(select(Gym).filter(Gym.gymID == gym_id, Gym.adminID == admin_id))
    gym = result.scalars().first()
    if not gym:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Gym not found or does not belong to you.")
    return gym


async def get_all_gyms_by_admin(db: AsyncSession, admin_id: int, skip: int = 0, limit: int = 100) -> list[Gym]:
    result = await db.execute(select(Gym).filter(Gym.adminID == admin_id).offset(skip).limit(limit))
    return result.scalars().all()


async def create_gym(db: AsyncSession, gym_data: GymCreate, admin_id: int) -> Gym:
    data = gym_data.model_dump()
    data["adminID"] = admin_id
    new_gym = Gym(**data)
    try:
        db.add(new_gym)
        await db.commit()
        await db.refresh(new_gym)
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Could not create gym. Check all fields are valid.")
    return new_gym


async def update_gym(db: AsyncSession, gym_id: int, gym_data: GymUpdate, admin_id: int) -> Gym:
    gym = await get_gym_by_admin(db, gym_id, admin_id)
    updated_fields = gym_data.model_dump(exclude_unset=True)
    updated_fields.pop("adminID", None)
    for field, value in updated_fields.items():
        setattr(gym, field, value)
    try:
        await db.commit()
        await db.refresh(gym)
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Update failed.")
    return gym


async def delete_gym(db: AsyncSession, gym_id: int, admin_id: int) -> dict:
    gym = await get_gym_by_admin(db, gym_id, admin_id)
    await db.delete(gym)
    await db.commit()
    return {"detail": f"Gym with ID {gym_id} deleted successfully."}