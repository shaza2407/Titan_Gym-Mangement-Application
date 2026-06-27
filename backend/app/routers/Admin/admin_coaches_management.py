from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies.auth import get_current_user
from app.database import get_session
from app.models.User import User
from app.models.Gym import Gym
from app.schemas.coach.coach_schemas import (
    InviteCoachRequest, InviteCoachResponse,
    CoachListResponse
)
from app.dependencies.gym_member_managment import get_admin_gym

router = APIRouter(prefix="/admin/gyms/{gym_id}/coaches", tags=["Admin - Coach Management"])

from app.services.admin.admin_coach_management_service import (
    get_coaches_list, invite_coach,
    suspend_a_coach, unsuspend_a_coach,
    accept_coach_invitation_service,
    decline_coach_invitation_service
)


# GET /admin/gyms/{gym_id}/coaches
@router.get("", response_model=CoachListResponse)
async def list_coaches(status_filter: str | None = None,  # "active" | "pending" | "suspended"
                       search: str | None = None,
                       db: AsyncSession = Depends(get_session),
                       gym: Gym = Depends(get_admin_gym),
                       ):

    return await get_coaches_list(db, gym, status_filter, search)



# POST /admin/gyms/{gym_id}/coaches/invite
@router.post("/invite", response_model=InviteCoachResponse, status_code=201)
async def invite_member(body: InviteCoachRequest, db: AsyncSession = Depends(get_session), gym: Gym = Depends(get_admin_gym)):
    return await invite_coach(db, gym, body)

# POST /admin/gyms/{gym_id}/coaches/{coach_id}/suspend
@router.post("/{coach_id}/suspend")
async def suspend_coach(coach_id: int, db: AsyncSession = Depends(get_session), gym: Gym = Depends(get_admin_gym)):
    return await suspend_a_coach(db, gym, coach_id)


@router.post("/{user_id}/unsuspend")
async def unsuspend_coach(user_id: int, db: AsyncSession = Depends(get_session), gym: Gym = Depends(get_admin_gym)):
    return await unsuspend_a_coach(db, gym, user_id)


# POST /admin/gyms/{gym_id}/coaches/invitations/accept
@router.post("/invitations/accept")
async def accept_coach_invitation(token: str, db: AsyncSession = Depends(get_session), current_user: User = Depends(get_current_user)):
    return await accept_coach_invitation_service(db, token, current_user)

# POST /admin/gyms/{gym_id}/coaches/invitations/decline
@router.post("/invitations/decline")
async def decline_coach_invitation(token: str, db: AsyncSession = Depends(get_session), current_user: User = Depends(get_current_user)):
    return await decline_coach_invitation_service(db, current_user, token)

