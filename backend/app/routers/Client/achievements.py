from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.dependencies.auth import require_client
from app.models.client import Client
from app.services.coach.achievement_engine import achievement_engine

from sqlalchemy import select

router = APIRouter(prefix="/achievements", tags=["Achievements"])


async def _get_client(current_user, db: AsyncSession) -> Client:
    result = await db.execute(
        select(Client).where(Client.userID == int(current_user.userID))
    )
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only clients can view achievements.",
        )
    return client


@router.get(
    "/",
    summary="Get active achievements with progress for the authenticated client",
)
async def get_achievements(
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    """
    Returns only:
    • already-unlocked levels
    • the currently active (in-progress) level per chain

    Future locked levels are hidden per requirements.
    """
    client = await _get_client(current_user, db)
    return await achievement_engine.get_client_achievements(client.clientID, db)


@router.post(
    "/recalculate",
    summary="Force recalculation of all achievements for the current client",
)
async def recalculate_achievements(
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    """
    Recalculates ALL achievement chains from scratch.
    Useful after data imports or debugging.
    Event-specific updates (on_checkin, on_class_attended, on_plan_completed)
    are normally preferred for performance.
    """
    client = await _get_client(current_user, db)
    cid    = client.clientID

    # Fire all event handlers to rebuild every chain
    await achievement_engine.on_checkin(cid, db)
    await achievement_engine.on_class_attended(cid, db)
    await achievement_engine.on_plan_completed(cid, db)

    return await achievement_engine.get_client_achievements(cid, db)
