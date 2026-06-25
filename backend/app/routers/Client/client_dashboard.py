# app/routers/Client/client_dashboard.py

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date
from app.database import get_session
from app.dependencies.auth import require_client
from app.schemas.client.attendance_schema import DashboardStatsResponse
from app.services.client.client_utils import get_client_or_404, get_membership
from app.services.client.client_dashboard import get_dashboard_stats

router = APIRouter(prefix="/client", tags=["Client Dashboard"])


@router.get("/dashboard-stats", response_model=DashboardStatsResponse)
async def dashboard_stats(
    current_user=Depends(require_client),
    db: AsyncSession = Depends(get_session)
):
    client = await get_client_or_404(current_user.userID, db)
    membership = await get_membership(client.clientID, db)

    if not membership:
        return DashboardStatsResponse(
            total_visits=0,
            days_this_week=0,
            current_streak=0,
        )

    stats = await get_dashboard_stats(client.clientID, membership.gymID, db)
    days_remaining = (membership.subscription_end - date.today()).days

    return DashboardStatsResponse(
        total_visits=stats["total_visits"],
        days_this_week=stats["days_this_week"],
        current_streak=stats["current_streak"],
        gym_name=stats["gym_name"],
        subscription=membership.subscription,
        subscription_end=str(membership.subscription_end),
        days_remaining=days_remaining,
        membership_status=membership.status.value,
    )