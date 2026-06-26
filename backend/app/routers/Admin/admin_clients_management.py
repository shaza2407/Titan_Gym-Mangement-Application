from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_session
from app.dependencies.auth import get_current_user
from app.models import User
from app.models.Gym import Gym
from app.schemas.admin.renewMembershipRequest import RenewMembershipRequest
from app.schemas.client.client_schemas import (
    InviteClientRequest, InviteClientResponse,
    ClientListResponse,
)
from app.dependencies.gym_member_managment import get_admin_gym
from app.services.admin.admin_managment_service import (
    get_clients_list, invite_client,
    cancel_client_invitation, suspend_a_client,
    unsuspend_a_client, accept_client_invitation,
    decline_client_invitation, get_pending_invitations,
    renew_client_membership, preview_invitation_service
)


router = APIRouter(prefix="/admin/gyms", tags=["Admin - Client Management"])

# GET /admin/gyms/{gym_id}/clients
@router.get("/{gym_id}/clients", response_model=ClientListResponse)
async def list_clients(status_filter: str | None = None, search: str | None = None, db: AsyncSession = Depends(get_session), gym: Gym = Depends(get_admin_gym)):
    clients_list = await get_clients_list(db, gym, status_filter, search)
    return clients_list

# POST /admin/gyms/{gym_id}/clients/invite
@router.post("/{gym_id}/clients/invite", response_model=InviteClientResponse, status_code=201)
async def invite_member(body: InviteClientRequest, db: AsyncSession = Depends(get_session), gym: Gym = Depends(get_admin_gym)):
    return await invite_client(db, gym, body)


@router.delete("/{gym_id}/invitations/{email}")
async def cancel_invitation(gym_id: int, email: str, db: AsyncSession = Depends(get_session), current_user=Depends(get_current_user)):
    return await cancel_client_invitation(db, gym_id, email)



## POST /admin/gyms/{gym_id}/clients/{client_id}/suspend
@router.post("/{gym_id}/clients/{client_id}/suspend")
async def suspend_client(client_id: int, db: AsyncSession = Depends(get_session), gym: Gym = Depends(get_admin_gym)):
    return await suspend_a_client(db, gym, client_id)


#to unsuspend suspended client
@router.post("/{gym_id}/clients/{client_id}/unsuspend")
async def unsuspend_client(client_id: int, db: AsyncSession = Depends(get_session), gym: Gym = Depends(get_admin_gym)):
    return await unsuspend_a_client(db, gym, client_id)

#POST /admin/gyms/{gym_id}/invitations/accept
@router.post("/{gym_id}/invitations/accept")
async def accept_invitation(gym_id: int, token: str, db: AsyncSession = Depends(get_session), current_user: User = Depends(get_current_user)):
    return await accept_client_invitation(db, gym_id, token, current_user)


@router.post("/{gym_id}/invitations/decline")
async def decline_invitation(gym_id: int, token: str, db: AsyncSession = Depends(get_session), current_user: User = Depends(get_current_user)):
    return await decline_client_invitation(db, gym_id, token, current_user)


@router.get("/{gym_id}/invitations/pending")
async def get_pending_invitation(gym_id: int, db: AsyncSession = Depends(get_session), current_user: User = Depends(get_current_user)):
    return await get_pending_invitations(db, gym_id, current_user)



@router.post("/{gym_id}/clients/{client_id}/renew")
async def renew_membership(client_id: int, body: RenewMembershipRequest, db: AsyncSession = Depends(get_session), gym: Gym = Depends(get_admin_gym)):
    return await renew_client_membership(db, gym, client_id, body)


# GET /admin/gyms/{gym_id}/invitations/preview?token=...
@router.get("/{gym_id}/invitations/preview")
async def preview_invitation(gym_id: int, token: str, db: AsyncSession = Depends(get_session), current_user: User = Depends(get_current_user)):
    return await preview_invitation_service(db, current_user, gym_id, token)