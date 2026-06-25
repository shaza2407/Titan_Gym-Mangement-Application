from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.client import Client
from app.services.coach.achievement_engine import achievement_engine
from app.services.client.utils import get_client_by_user_id

async def get_client_achievements_service(user_id: int, db: AsyncSession):
    """Gets active achievements with progress for the client."""
    client = await get_client_by_user_id(user_id, db, detail="Only clients can view achievements.")
    return await achievement_engine.get_client_achievements(client.clientID, db)

async def recalculate_client_achievements_service(user_id: int, db: AsyncSession):
    """Force recalculates all achievements for the client."""
    client = await get_client_by_user_id(user_id, db, detail="Only clients can view achievements.")
    cid = client.clientID

    # Fire all event handlers to rebuild every chain
    await achievement_engine.on_checkin(cid, db)
    await achievement_engine.on_class_attended(cid, db)
    await achievement_engine.on_plan_completed(cid, db)

    return await achievement_engine.get_client_achievements(cid, db)
