# app/routers/Client/client_profile.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_session
from app.dependencies.auth import require_client
from app.schemas.client.client_profile_schema import ClientProfileUpdate, ClientProfileResponse
from app.services.client.client_profile import get_client_profile, update_client_profile
from app.services.client.client_utils import get_client_or_404, get_membership

router = APIRouter(prefix="/client", tags=["Client Profile"])


@router.get("/profile", response_model=ClientProfileResponse)
async def get_profile(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session)
):
    profile = await get_client_profile(current_user.userID, db)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile


@router.put("/profile", response_model=ClientProfileResponse)
async def update_profile(
    payload: ClientProfileUpdate,
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session)
):
    updated = await update_client_profile(current_user.userID, payload, db)
    if not updated:
        raise HTTPException(status_code=404, detail="Profile not found")
    return updated


@router.get("/me")
async def get_me(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session)
):
    client = await get_client_or_404(current_user.userID, db)
    membership = await get_membership(client.clientID, db)

    return {
        "userID":       current_user.userID,
        "name":         current_user.name,
        "email":        current_user.email,
        "is_connected": membership is not None,
    }