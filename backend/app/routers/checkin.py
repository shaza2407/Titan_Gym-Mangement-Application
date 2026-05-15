# app/routers/checkin.py
"""
Endpoints
─────────
POST /checkin/         – Client scans QR code → creates a CheckIn record
GET  /checkin/history  – Returns client's past check-ins

BUG FIXES:
1. Both routes now use require_client — previously coaches/admins could
   POST a check-in or read someone else's history (if they somehow got
   a client record, which is impossible but good practice regardless).
2. Duplicate check-in guard added: prevent the same client checking in
   twice on the same calendar day (avoids inflating streak / monthly counts).
3. CheckInResponse schema was missing model_config — added from_attributes.
"""

from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, cast, Date

from app.database import get_session
from app.dependencies.auth import require_client
from app.models.client import Client
from app.models.check_in import CheckIn
from app.models.Gym import Gym
from app.schemas.achievement_schemas import CheckInRequest, CheckInResponse

router = APIRouter(prefix="/checkin", tags=["Check-In"])


async def _get_client(current_user, db: AsyncSession) -> Client:
    result = await db.execute(
        select(Client).where(Client.userID == int(current_user.userID))
    )
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only clients can check in.",
        )
    return client


@router.post(
    "/",
    response_model=CheckInResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Record a gym check-in after QR scan",
)
async def check_in(
    req: CheckInRequest,
    # BUG FIX: require_client instead of bare get_current_user
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client = await _get_client(current_user, db)

    # Validate the gym exists
    gym_result = await db.execute(select(Gym).where(Gym.gymID == req.gymID))
    gym = gym_result.scalar_one_or_none()
    if not gym:
        raise HTTPException(status_code=404, detail="Gym not found.")

    now       = datetime.now(timezone.utc)
    today_utc = now.date()

    # BUG FIX: prevent duplicate check-ins on the same calendar day
    duplicate = await db.execute(
        select(CheckIn).where(
            CheckIn.clientID == client.clientID,
            CheckIn.gymID    == req.gymID,
            func.date(CheckIn.checked_in_at) == today_utc,
        )
    )
    if duplicate.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Already checked in at this gym today.",
        )

    new_checkin = CheckIn(
        clientID      = client.clientID,
        gymID         = req.gymID,
        checked_in_at = now,
        check_in_hour = now.hour,
    )
    db.add(new_checkin)
    await db.commit()
    await db.refresh(new_checkin)

    message = f"Welcome to {gym.gymName}! Keep it up 💪"
    if now.hour < 7:
        message = f"Early bird! Welcome to {gym.gymName} 🌅"

    return CheckInResponse(
        checkInID     = new_checkin.checkInID,
        gymID         = new_checkin.gymID,
        checked_in_at = new_checkin.checked_in_at,
        message       = message,
    )


@router.get(
    "/history",
    summary="Get check-in history for the authenticated client",
)
async def get_checkin_history(
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client = await _get_client(current_user, db)
    result = await db.execute(
        select(CheckIn)
        .where(CheckIn.clientID == client.clientID)
        .order_by(CheckIn.checked_in_at.desc())
        .limit(100)
    )
    return result.scalars().all()
