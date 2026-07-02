from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select , func
import secrets
from datetime import datetime, timedelta, date ,date as date_type
from app.services.notifications.notification_Utils import notify_invite
from dateutil.relativedelta import relativedelta
from app.models import User
from app.models.client import Client
from app.models.Gym import Gym
from app.models.notification import Notification
from app.models.subscription import Subscription
from app.models.gym_clients_membership import GymClientMembership, ClientMembershipStatus
from app.models.member_invitation import MemberInvitation, InvitationStatus
from app.schemas.shared.UserRole import UserRole
from app.schemas.admin.renewMembershipRequest import RenewMembershipRequest
from app.schemas.client.client_schemas import (
    InviteClientRequest, InviteClientResponse,
    ClientListResponse, ClientListItem,
)

from app.models import Attendance


async def get_clients_list(db: AsyncSession, gym: Gym,status_filter: str | None = None, search: str | None = None):

    members: list[ClientListItem] = []

    rows = (await db.execute(select(GymClientMembership, Client, User)
                             .join(Client, GymClientMembership.clientID == Client.clientID)
                             .join(User, Client.userID == User.userID)
                             .where(GymClientMembership.gymID == gym.gymID)
                             )).all()

    visit_counts_result = await db.execute(
        select(Attendance.clientID, func.count(Attendance.id).label("visits"))
        .where(Attendance.gymID == gym.gymID)
        .group_by(Attendance.clientID)
    )
    visit_map = {r.clientID: r.visits for r in visit_counts_result.all()}

    member_emails = set()

    for membership, client, user in rows:
        if search:
            term = search.lower()
            if term not in user.name.lower() and term not in user.email.lower():
                continue

        if (membership.status == ClientMembershipStatus.active
                and membership.subscription_end is not None
                and membership.subscription_end < date.today()
        ):
            display_status = "expired"
        else:
            display_status = membership.status.value

        if display_status in ("active", "expired"):
            member_emails.add(user.email.lower())

        members.append(ClientListItem(
            id=user.userID,
            name=user.name,
            email=user.email.lower(),
            phone=user.phone,
            status=display_status,
            subscription=membership.subscription,
            subscription_end=membership.subscription_end,
            visits=visit_map.get(client.clientID, 0),
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
        if inv.email.lower() in member_emails:
            continue
        members.append(ClientListItem(
            id=inv.id,
            name="Pending Invitation",
            email=inv.email.lower(),
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


async def invite_client(db: AsyncSession, gym: Gym, body: InviteClientRequest) -> InviteClientResponse:
    #check if user found in the whole application
    existing_user = (await db.execute(
        select(User).where(User.email == body.email.lower())
    )).scalar_one_or_none()

    if not existing_user:
        raise HTTPException(422, "No user found with this email.")

    #check if it's a client
    if existing_user.role != UserRole.client:
        raise HTTPException(400, "This user is not a client.")

    # block only if ACTIVE in the same gym
    active_membership = (await db.execute(
        select(GymClientMembership)
        .join(Client, GymClientMembership.clientID == Client.clientID)
        .where(
            Client.userID == existing_user.userID,
            GymClientMembership.gymID == gym.gymID,
            GymClientMembership.status == ClientMembershipStatus.active,
        )
    )).scalar_one_or_none()

    if active_membership:
        raise HTTPException(400, "This client is already an active member of this gym.")

    #if in the gym but suspended member
    suspended_membership = (await db.execute(
        select(GymClientMembership)
        .join(Client, GymClientMembership.clientID == Client.clientID)
        .where(
            Client.userID == existing_user.userID,
            GymClientMembership.gymID == gym.gymID,
            GymClientMembership.status == ClientMembershipStatus.suspended,
        )
    )).scalar_one_or_none()

    if suspended_membership :
        raise HTTPException(400, "This client is already a suspended member in this gym ,unsuspend him.")

    ## check for existing pending invitation
    existing_inv = (await db.execute(
        select(MemberInvitation).where(
            MemberInvitation.gymID == gym.gymID,
            MemberInvitation.email == body.email.lower(),
            MemberInvitation.status == InvitationStatus.pending,
            MemberInvitation.invited_as == "client",
        )
    )).scalar_one_or_none()

    now = datetime.now()
    if body.subscription_type == "yearly":
        subscription_label = "yearly"
        subscription_end = (now + relativedelta(years=body.subscription_months)).date()
    else:
        subscription_label = "monthly"
        subscription_end = (now + relativedelta(months=body.subscription_months)).date()

    existing_notification = (await db.execute(
    select(Notification).where(
        Notification.data["gym_id"].as_integer() == gym.gymID,
        Notification.user_id == existing_user.userID,
        Notification.is_read == False,
    )
    )).scalar_one_or_none()

    #if it's already there just extend invitation expiration
    if existing_inv:
        existing_inv.token = secrets.token_urlsafe(32)
        existing_inv.sent_at = datetime.now()
        existing_inv.expires_at = datetime.now() + timedelta(days=3)
        existing_inv.subscription = subscription_label
        existing_inv.subscription_end = subscription_end
        existing_inv.subscription_price = body.subscription_price
        existing_inv.duration_count = body.subscription_months
        inv = existing_inv
    #if no old inviation, make a new one
    else:
        inv = MemberInvitation(
            gymID=gym.gymID,
            email=body.email.lower(),
            invited_as="client",
            token=secrets.token_urlsafe(32),
            status=InvitationStatus.pending,
            expires_at=datetime.now() + timedelta(days=3),
            subscription=subscription_label,
            subscription_end=subscription_end,
            subscription_price=body.subscription_price,
            duration_count=body.subscription_months,
        )
        db.add(inv)

    if existing_notification :
        await db.delete(existing_notification)

    await notify_invite(db, body.email.lower(), gym.gymName, "client", gym_id=gym.gymID, token=inv.token)
    await db.commit()
    return InviteClientResponse(message="Invitation sent successfully.", email=body.email.lower())




async def cancel_client_invitation(db: AsyncSession, gym_id: int, email: str):
    invitation = (await db.execute(
        select(MemberInvitation).where(
            MemberInvitation.gymID == gym_id,
            MemberInvitation.email == email.lower(),
            MemberInvitation.status == InvitationStatus.pending,
            MemberInvitation.invited_as == "client",
        )
    )).scalar_one_or_none()

    if not invitation:
        raise HTTPException(status_code=404, detail="Invitation not found")

    # find the user by email to get their user_id
    user = (await db.execute(
        select(User).where(User.email == email.lower())
    )).scalar_one_or_none()

    # delete the invite notification for that user
    if user:
        notifications = (await db.execute(
            select(Notification).where(
                Notification.user_id == user.userID,
                Notification.type == "gym_invite_client",
            )
        )).scalars().all()
        for n in notifications:
            await db.delete(n)

    await db.delete(invitation)
    await db.commit()
    return {"detail": "Invitation cancelled"}


async def suspend_a_client(db: AsyncSession, gym: Gym, client_id: int):
    membership = (await db.execute(
        select(GymClientMembership)
        .join(Client, GymClientMembership.clientID == Client.clientID)
        .where(
            GymClientMembership.gymID == gym.gymID,
            Client.userID == client_id,
        )
    )).scalar_one_or_none()

    if not membership:
        raise HTTPException(404, "Client not found in this gym.")
    if membership.status != ClientMembershipStatus.active:
        raise HTTPException(400, "Only active memberships can be suspended.")

    membership.status = ClientMembershipStatus.suspended
    await db.commit()
    return {"message": "Client suspended successfully."}


async def unsuspend_a_client(db: AsyncSession, gym: Gym, client_id: int):
    membership = (await db.execute(
        select(GymClientMembership)
        .join(Client, GymClientMembership.clientID == Client.clientID)
        .where(
            GymClientMembership.gymID == gym.gymID,
            Client.userID == client_id,
        )
    )).scalar_one_or_none()

    if not membership:
        raise HTTPException(404, "Client not found in this gym.")

    # check if subscription is expired
    if membership.subscription_end and membership.subscription_end < date_type.today():
        raise HTTPException(400, "Membership expired. Please renew first.")

    # block if client has an active membership at another gym
    other_active = (await db.execute(
        select(GymClientMembership).where(
            GymClientMembership.clientID == membership.clientID,
            GymClientMembership.status == ClientMembershipStatus.active,
            GymClientMembership.gymID != gym.gymID,
        )
    )).scalar_one_or_none()

    if other_active:
        raise HTTPException(
            400,
            "This client now has an active membership at another gym. "
            "Please send a new invitation to re-add them to this gym."
        )

    membership.status = ClientMembershipStatus.active
    await db.commit()
    return {"message": "Client unsuspended successfully."}

async def accept_client_invitation(db: AsyncSession, gym_id: int, token: str, current_user: User):
    inv = (await db.execute(
        select(MemberInvitation).where(
            MemberInvitation.token == token,
            MemberInvitation.gymID == gym_id,
            MemberInvitation.status == InvitationStatus.pending,
        )
    )).scalar_one_or_none()

    # safety checks
    if not inv:
        raise HTTPException(404, "Invitation not found or already used.")

    if inv.expires_at < datetime.now():
        raise HTTPException(400, "Invitation has expired.")

    if inv.email.lower() != current_user.email.lower():
        raise HTTPException(403, "This invitation is not for your account.")

    client = (await db.execute(
        select(Client).where(Client.userID == current_user.userID)
    )).scalar_one_or_none()

    if not client:
        raise HTTPException(404, "Client profile not found.")

    # only block if there's an ACTIVE membership at this exact gym
    already_active = (await db.execute(
        select(GymClientMembership).where(
            GymClientMembership.clientID == client.clientID,
            GymClientMembership.gymID == gym_id,
            GymClientMembership.status == ClientMembershipStatus.active,
        )
    )).scalar_one_or_none()

    if already_active:
        raise HTTPException(400, "Already a member of this gym.")

    # delete any existing membership at this same gym (cascade handles its children)
    old_membership = (await db.execute(
        select(GymClientMembership).where(
            GymClientMembership.clientID == client.clientID,
            GymClientMembership.gymID == gym_id,
        )
    )).scalar_one_or_none()

    if old_membership:
        await db.delete(old_membership)
        await db.flush()

    # delete all memberships at every other gym (cascade handles their children)
    other_memberships = (await db.execute(
        select(GymClientMembership).where(
            GymClientMembership.clientID == client.clientID,
            GymClientMembership.gymID != gym_id,
        )
    )).scalars().all()

    for m in other_memberships:
        await db.delete(m)

    await db.flush()

    # create fresh membership
    membership = GymClientMembership(
        clientID=client.clientID,
        gymID=gym_id,
        status=ClientMembershipStatus.active,
        subscription=inv.subscription,
        subscription_end=inv.subscription_end,
    )
    db.add(membership)
    await db.flush()

    # create subscription record
    subscription = Subscription(
        clientID=client.clientID,
        gymID=gym_id,
        # gymClientMebershipID=membership.id,
        supscriptionPrice=inv.subscription_price,
        duration_count=inv.duration_count,
    )
    db.add(subscription)
    await db.delete(inv)
    # inv.status = InvitationStatus.accepted

    await db.commit()
    return {"message": "Invitation accepted. You are now a member!"}


async def decline_client_invitation(db: AsyncSession, gym_id: int, token: str, current_user: User):
    inv = (await db.execute(
        select(MemberInvitation).where(
            MemberInvitation.token == token,
            MemberInvitation.gymID == gym_id,
            MemberInvitation.status == InvitationStatus.pending,
        )
    )).scalar_one_or_none()

    if not inv:
        raise HTTPException(404, "Invitation not found.")

    if inv.email.lower() != current_user.email.lower():
        raise HTTPException(403, "This invitation is not for your account.")

    # inv.status = InvitationStatus.declined
    db.delete(inv)
    await db.commit()
    return {"message": "Invitation declined."}


async def get_pending_invitations(db: AsyncSession, gym_id: int, current_user: User):
    inv = (await db.execute(
        select(MemberInvitation).where(
            MemberInvitation.gymID == gym_id,
            MemberInvitation.email == current_user.email.lower(),
            MemberInvitation.status == InvitationStatus.pending,
        )
    )).scalar_one_or_none()

    if not inv:
        raise HTTPException(404, "No pending invitation found.")

    return {
        "token": inv.token,
        "gym_id": inv.gymID,
        "expires_at": inv.expires_at,
    }



async def renew_client_membership(db: AsyncSession, gym: Gym, client_id: int, body: RenewMembershipRequest):
    # Get membership
    membership = (await db.execute(
        select(GymClientMembership)
        .join(Client, GymClientMembership.clientID == Client.clientID)
        .where(
            GymClientMembership.gymID == gym.gymID,
            Client.userID == client_id,
        )
    )).scalar_one_or_none()

    #if client id is not found in the gym
    if not membership:
        raise HTTPException(404, "Client not found in this gym.")

    #calculate new expiry - extend from today if expired, or from current end if still active member
    today = date.today()
    base_date = max(membership.subscription_end, today) if membership.subscription_end else today

    if body.subscription_type == "yearly":
        new_end = base_date + relativedelta(years=body.duration_count)
        subscription_label = "yearly"
    else:
        new_end = base_date + relativedelta(months=body.duration_count)
        subscription_label = "monthly"

    #update membership (subscription end and subscription -> type)
    membership.subscription_end = new_end
    membership.subscription = subscription_label
    membership.status = ClientMembershipStatus.active  #reactivate if suspended

    # Log subscription record
    sub = Subscription(
        clientID = membership.clientID,
        gymID = membership.gymID ,
        # gymClientMebershipID=membership.id,
        supscriptionPrice=int(body.price),
        duration_count=body.duration_count,
    )
    db.add(sub)

    await db.commit()
    return {
        "message": "Membership renewed successfully.",
        "new_subscription_end": str(new_end),
        "subscription": subscription_label,
    }


async def preview_invitation_service(db: AsyncSession, current_user: User, gym_id: int, token: str):
    inv = (await db.execute(
        select(MemberInvitation).where(
            MemberInvitation.token == token,
            MemberInvitation.gymID == gym_id,
            MemberInvitation.status == InvitationStatus.pending,
        )
    )).scalar_one_or_none()

    if not inv:
        raise HTTPException(404, "Invitation not found or already used.")

    client = (await db.execute(
        select(Client).where(Client.userID == current_user.userID)
    )).scalar_one_or_none()

    other_active_gyms = []
    if client:
        rows = (await db.execute(
            select(Gym.gymName)
            .join(GymClientMembership, GymClientMembership.gymID == Gym.gymID)
            .where(
                GymClientMembership.clientID == client.clientID,
                GymClientMembership.status == ClientMembershipStatus.active,
                GymClientMembership.gymID != gym_id,
            )
        )).all()
        other_active_gyms = [r.gymName for r in rows]

    gym = (await db.execute(
        select(Gym).where(Gym.gymID == gym_id)
    )).scalar_one_or_none()

    if not gym:
        raise HTTPException(404, "Gym not found.")

    return {
        "gym_name": gym.gymName if gym else None,
        "will_suspend_other_memberships": len(other_active_gyms) > 0,
        "other_active_gyms": other_active_gyms,
    }