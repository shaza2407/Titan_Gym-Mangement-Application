from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.database import get_session
from app.schemas.gym import GymCreate, GymUpdate, GymResponse
from app.services import gym as gym_crud
from app.models import User , Admin
from app.dependencies.auth import require_admin
from app.schemas.gym import GymCreate, GymUpdate, GymResponse, GymDashboardStats 
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_session
from app.dependencies.auth import get_current_user


router = APIRouter(
    prefix="/gyms",
    tags=["Gyms"],
)


@router.get("/", response_model=list[GymResponse], status_code=status.HTTP_200_OK)
async def list_my_gyms(skip: int = 0, limit: int = 100, db: Session = Depends(get_session), current_admin: Admin = Depends(require_admin)):
    return await gym_crud.get_all_gyms_by_admin(db, admin_id=current_admin.adminID, skip=skip, limit=limit)


@router.get("/{gym_id}/dashboard", response_model=GymDashboardStats, status_code=status.HTTP_200_OK)
async def get_gym_dashboard(gym_id: int, db: Session = Depends(get_session), current_admin: Admin = Depends(require_admin)):
    return await gym_crud.get_dashboard_stats(db, gym_id=gym_id, admin_id=current_admin.adminID)


@router.get("/{gym_id}", response_model=GymResponse, status_code=status.HTTP_200_OK)
async def get_gym(gym_id: int, db: Session = Depends(get_session), current_admin: Admin = Depends(require_admin)):
    return await gym_crud.get_gym_by_admin(db, gym_id=gym_id, admin_id=current_admin.adminID)


@router.post("/", response_model=GymResponse, status_code=status.HTTP_201_CREATED)
async def create_gym(gym_data: GymCreate, db: Session = Depends(get_session), current_admin: Admin = Depends(require_admin)):
    return await gym_crud.create_gym(db, gym_data=gym_data, admin_id = current_admin.adminID)


@router.patch("/{gym_id}", response_model=GymResponse, status_code=status.HTTP_200_OK)
async def update_gym(gym_id: int, gym_data: GymUpdate, db: Session = Depends(get_session), current_admin: Admin = Depends(require_admin)):
    return await gym_crud.update_gym(db, gym_id=gym_id, gym_data=gym_data, admin_id=current_admin.adminID)


@router.delete("/{gym_id}", status_code=status.HTTP_200_OK)
async def delete_gym( gym_id: int, db: Session = Depends(get_session), current_admin: Admin = Depends(require_admin)):
    return await gym_crud.delete_gym(db, gym_id=gym_id, admin_id=current_admin.adminID)

async def update_gym_endpoint(
    gym_id: int,
    body: GymUpdate,
    db: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    # Get adminID from current user
    result = await db.execute(select(Admin).where(Admin.userID == current_user.userID))
    admin = result.scalar_one_or_none()
    if not admin:
        raise HTTPException(403, "User is not an admin.")

    gym = await update_gym(db, gym_id, body, admin.adminID)
    return {"message": "Gym updated successfully."}

