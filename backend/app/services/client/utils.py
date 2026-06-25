from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.client import Client

async def get_client_by_user_id(user_id: int, db: AsyncSession, detail: str = "Only clients can perform this action.") -> Client:
    result = await db.execute(
        select(Client).where(Client.userID == user_id)
    )
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=detail,
        )
    return client
