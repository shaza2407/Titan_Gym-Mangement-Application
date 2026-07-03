from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.dependencies.auth import require_client
from app.services.client.achievements import (
    get_client_achievements_service,
    recalculate_client_achievements_service,
)

router = APIRouter(prefix="/achievements", tags=["Achievements"])

@router.get(
    "/",
    summary="Get active achievements with progress for the authenticated client",
)
async def get_achievements(
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    return await get_client_achievements_service(int(current_user.userID), db)


@router.post(
    "/recalculate",
    summary="Force recalculation of all achievements for the current client",
)
async def recalculate_achievements(
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    return await recalculate_client_achievements_service(int(current_user.userID), db)
