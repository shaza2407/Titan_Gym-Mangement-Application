
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_session
from app.models import Client, GymClientMembership
from app.schemas.client_profile_schema import ClientProfileUpdate, ClientProfileResponse
from app.CRUD.client_profile import get_client_profile, update_client_profile
from app.dependencies.auth import require_client

router = APIRouter(prefix="/client", tags=["Client"])


async def get_client_or_404(userID: int, db: AsyncSession) -> Client:
    result = await db.execute(select(Client).where(Client.userID == userID))
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(status_code=404, detail="Client profile not found")
    return client


async def is_connected_to_gym(clientID: int, db: AsyncSession) -> bool:
    result = await db.execute(
        select(GymClientMembership).where(GymClientMembership.clientID == clientID)
    )
    return result.scalar_one_or_none() is not None


# GET /client/profile
@router.get("/profile", response_model=ClientProfileResponse)
async def get_profile(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session)
):
    profile = await get_client_profile(current_user.userID, db)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile


# PUT /client/profile
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


# GET /client/me
# Returns basic info + whether client is connected to a gym
# Frontend uses this right after sign in to decide which page to show
@router.get("/me")
async def get_me(
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session)
):
    client = await get_client_or_404(current_user.userID, db)
    connected = await is_connected_to_gym(client.clientID, db)

    return {
        "userID":           current_user.userID,
        "name":             current_user.name,
        "email":            current_user.email,
        "is_connected":     connected,    # frontend checks this
    }