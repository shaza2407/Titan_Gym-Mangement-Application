#done testing
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_session
from app.models.User import User
from app.dependencies.auth import get_current_user
from app.schemas.admin.admin_profile import AdminProfileUpdate
from app.services.admin import admin_profile_service

router = APIRouter(prefix="/admin", tags=["Admin"])

@router.get("/profile")
async def get_admin_profile(db: AsyncSession = Depends(get_session),current_user: User = Depends(get_current_user),):
    return await admin_profile_service.get_profile(db, current_user)

@router.put("/profile")
async def update_admin_profile(data: AdminProfileUpdate,db: AsyncSession = Depends(get_session),current_user: User = Depends(get_current_user),):
    return await admin_profile_service.update_profile(db, current_user, data)