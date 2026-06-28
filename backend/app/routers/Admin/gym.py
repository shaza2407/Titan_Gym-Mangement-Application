#done testing
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.database import get_session
from app.schemas.admin.gym import GymCreate, GymUpdate, GymResponse
from app.services.admin import gym_service as gym_crud
from app.dependencies.auth import require_admin
from app.schemas.admin.gym import GymCreate, GymUpdate, GymResponse, GymDashboardStats
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_session
from app.dependencies.auth import get_current_user
from app.models import User , Admin
from app.services.admin.gym_service import (get_total_members, get_member_count,get_coach_count, get_class_count)

router = APIRouter(
    prefix="/gyms",
    tags=["Gyms"],
)


@router.get("/", response_model=list[GymResponse], status_code=status.HTTP_200_OK)
async def list_my_gyms(skip: int = 0, limit: int = 100, db: Session = Depends(get_session), current_admin: Admin = Depends(require_admin)):
    return await gym_crud.get_all_gyms_by_admin(db, admin_id=current_admin.adminID, skip=skip, limit=limit)

@router.post("/", response_model=GymResponse, status_code=status.HTTP_201_CREATED)
async def create_gym(gym_data: GymCreate, db: Session = Depends(get_session), current_admin: Admin = Depends(require_admin)):
    return await gym_crud.create_gym(db, gym_data=gym_data, admin_id=current_admin.adminID)


@router.get("/total-members")
async def get_all_total_members( db: AsyncSession = Depends(get_session),current_user: User = Depends(get_current_user),):
    total = await get_total_members(db=db, user_id=current_user.userID)
    return {"total": total}


@router.get("/{gym_id}/member-count")
async def get_gym_member_count(gym_id: int, db: AsyncSession = Depends(get_session), current_user: User = Depends(get_current_user), ):
    count = await get_member_count(db=db, gym_id=gym_id)
    return {"count": count}


@router.get("/{gym_id}/coach-count")
async def get_gym_coach_count(gym_id: int, db: AsyncSession = Depends(get_session), current_user: User = Depends(get_current_user),):
    count = await get_coach_count(db=db, gym_id=gym_id)
    return {"count": count}

@router.get("/{gym_id}/class-count")
async def get_gym_class_count(gym_id: int, db: AsyncSession = Depends(get_session), current_user: User = Depends(get_current_user),):
    count = await get_class_count(db=db, gym_id=gym_id)
    return {"count" : count}

@router.get("/{gym_id}/dashboard", response_model=GymDashboardStats, status_code=status.HTTP_200_OK)
async def get_gym_dashboard(gym_id: int, db: Session = Depends(get_session), current_admin: Admin = Depends(require_admin)):
    return await gym_crud.get_dashboard_stats(db, gym_id=gym_id, admin_id=current_admin.adminID)


@router.get("/{gym_id}", response_model=GymResponse, status_code=status.HTTP_200_OK)
async def get_gym(gym_id: int, db: Session = Depends(get_session), current_admin: Admin = Depends(require_admin)):
    return await gym_crud.get_gym_by_admin(db, gym_id=gym_id, admin_id=current_admin.adminID)


@router.patch("/{gym_id}", response_model=GymResponse, status_code=status.HTTP_200_OK)
async def update_gym(gym_id: int, gym_data: GymUpdate, db: Session = Depends(get_session), current_admin: Admin = Depends(require_admin)):
    return await gym_crud.update_gym(db, gym_id=gym_id, gym_data=gym_data, admin_id=current_admin.adminID)


@router.delete("/{gym_id}", status_code=status.HTTP_200_OK)
async def delete_gym(gym_id: int, db: Session = Depends(get_session), current_admin: Admin = Depends(require_admin)):
    return await gym_crud.delete_gym(db, gym_id=gym_id, admin_id=current_admin.adminID)


