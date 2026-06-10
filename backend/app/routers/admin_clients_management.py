from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select , func
import secrets
from datetime import datetime, timedelta, date

from app.database import get_session
from app.dependencies.auth import get_current_user
from app.models import User , Admin
from app.models.client import Client
from app.models.Gym import Gym
from app.models.gym_clients_membership import GymClientMembership, ClientMembershipStatus
from app.models.member_invitation import MemberInvitation, InvitationStatus
from app.schemas.UserRole import UserRole
from app.schemas.client_schemas import (
    InviteClientRequest, InviteClientResponse,
    ClientListResponse, ClientListItem,
)
from app.email_utils import send_invitation_email
from app.dependencies.gym_member_managment import get_admin_gym



router = APIRouter(prefix="/admin/gyms", tags=["Admin - Client Management"])

# GET /admin/gyms/{gym_id}/clients
@router.get("/{gym_id}/clients", response_model=ClientListResponse)
async def list_clients(status_filter: str | None = None,
                       search: str | None = None,
                       db: AsyncSession = Depends(get_session),
                       gym: Gym = Depends(get_admin_gym),
                       ):

    members: list[ClientListItem] = []

    rows = (await db.execute(select(GymClientMembership, Client, User)
                             .join(Client, GymClientMembership.clientID == Client.clientID)
                             .join(User, Client.userID == User.userID)  # ← correct join path
                             .where(GymClientMembership.gymID == gym.gymID)
                             )).all()

    for membership, client, user in rows:
        # search filter
        if search:
            term = search.lower()
            if term not in user.name.lower() and term not in user.email.lower():
                continue

        # compute display status: active vs expired
        if (membership.status == ClientMembershipStatus.active
                and membership.subscription_end is not None
                and membership.subscription_end < date.today()
        ):
            display_status = "expired"
        else:
            display_status = membership.status.value  # "active" or "suspended"

        members.append(ClientListItem(
            id=user.userID,
            name=user.name,
            email=user.email,
            phone=user.phone,
            status=display_status,
            subscription=membership.subscription,
            subscription_end=membership.subscription_end,
            visits=None,  # wire up when visits table is ready
            joined=membership.joined_at,
            invitation_sent=None,
        ))

    ###   invited clients
    invitations = (await db.execute(select(MemberInvitation)
                                    .where(MemberInvitation.gymID  == gym.gymID,
                                           MemberInvitation.status == InvitationStatus.pending,
                                           MemberInvitation.invited_as == "client",)
                                    )).scalars().all()

    for inv in invitations:
        if search and search.lower() not in inv.email.lower():
            continue
        members.append(ClientListItem(
            id=inv.id,
            name="Pending Invitation",
            email=inv.email,
            phone=None,
            status="pending",
            subscription=None,
            subscription_end=None,
            visits=None,
            joined=None,
            invitation_sent=inv.sent_at,
        ))

    if status_filter == "active":
        members = [m for m in members if m.status == "active"]
    elif status_filter == "expired":
        members = [m for m in members if m.status == "expired"]
    elif status_filter == "pending":
        members = [m for m in members if m.status == "pending"]

    active_count = sum(1 for m in members if m.status == "active")
    pending_count = sum(1 for m in members if m.status == "pending")
    expired_count = sum(1 for m in members if m.status == "expired")

    return ClientListResponse(
        total=len(members),
        active=active_count,
        pending=pending_count,
        expired=expired_count,
        members=members,
    )


# POST /admin/gyms/{gym_id}/clients/invite
@router.post("/{gym_id}/clients/invite", response_model=InviteClientResponse, status_code=201)
async def invite_member(body: InviteClientRequest,
                        db: AsyncSession = Depends(get_session),
                        gym: Gym = Depends(get_admin_gym),
                        ):
    # 1. Check the email exists in the app
    existing_user = (await db.execute(
        select(User).where(User.email == body.email)
    )).scalar_one_or_none()

    if not existing_user:
        raise HTTPException(404, "No user found with this email.")

    # 2. Check the user is a client
    if existing_user.role != UserRole.client:
        raise HTTPException(400, "This user is not a client.")

    # 3. Check the user isn't already a member of this gym
    already_member = (await db.execute(
        select(GymClientMembership).where(
            GymClientMembership.clientID == existing_user.userID,
            GymClientMembership.gymID == gym.gymID,
        )
    )).scalar_one_or_none()

    if already_member:
        raise HTTPException(400, "This client is already a member of this gym.")


    ## 4. Check for existing pending invitation
    existing_inv = (await db.execute(
        select(MemberInvitation).where(
            MemberInvitation.gymID == gym.gymID,
            MemberInvitation.email == body.email,
            MemberInvitation.status == InvitationStatus.pending,
            MemberInvitation.invited_as == "client",
        )
    )).scalar_one_or_none()

    if existing_inv:
        existing_inv.token = secrets.token_urlsafe(32)
        existing_inv.sent_at = datetime.utcnow()
        existing_inv.expires_at = datetime.utcnow() + timedelta(days=3)
        inv = existing_inv
    else:
        inv = MemberInvitation(
            gymID=gym.gymID,
            email=body.email,
            invited_as="client",
            token=secrets.token_urlsafe(32),
            status=InvitationStatus.pending,
            expires_at=datetime.utcnow() + timedelta(days=3),
        )
        db.add(inv)
    await db.commit()
    await send_invitation_email(body.email, gym.gymName, inv.token)

    return InviteClientResponse(message="Invitation sent successfully.", email=body.email)

## POST /admin/gyms/{gym_id}/clients/{member_id}/suspend
@router.post("/{gym_id}/clients/{member_id}/suspend")
async def suspend_client(
    member_id: int,
    db: AsyncSession = Depends(get_session),
    gym: Gym = Depends(get_admin_gym),
):
    membership = (await db.execute(
        select(GymClientMembership)
        .join(Client, GymClientMembership.clientID == Client.clientID)
        .where(
            GymClientMembership.gymID == gym.gymID,
            Client.userID == member_id,
        )
    )).scalar_one_or_none()

    if not membership:
        raise HTTPException(404, "Client not found in this gym.")

    membership.status = ClientMembershipStatus.suspended
    await db.commit()
    return {"message": "Client suspended successfully."}


@router.get("/total-members")
async def get_total_members(db: AsyncSession = Depends(get_session), current_user: User = Depends(get_current_user),):
    # Get adminID from Admin table
    admin_result = await db.execute(select(Admin).where(Admin.userID == current_user.userID))
    admin = admin_result.scalars().first()

    if not admin:
        raise HTTPException(status_code=403, detail="User is not an admin")
    # Count members using adminID
    result = await db.execute(
        select(func.count(GymClientMembership.id))
        .join(Gym, GymClientMembership.gymID == Gym.gymID)
        .where(Gym.adminID == admin.adminID)
    )
    return {"total": result.scalar()}
