from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import secrets
from datetime import datetime, timedelta, timezone
from app.services.notifications.notification_service import notify_invite
from app.dependencies.auth import get_current_user
from app.database import get_session
from app.models.User import User
from app.models.coach import Coach
from app.models.Gym import Gym
from app.models.gym_coachs_membership import GymCoachMembership, CoachMembershipStatus
from app.models.member_invitation import MemberInvitation, InvitationStatus
from app.schemas.shared.UserRole import UserRole
from app.schemas.coach.coach_schemas import (
    InviteCoachRequest, InviteCoachResponse,
    CoachListResponse, CoachListItem,
)
from app.services.notifications.email_utils import send_invitation_email
from app.dependencies.gym_member_managment import get_admin_gym

router = APIRouter(prefix="/admin/gyms/{gym_id}/coaches", tags=["Admin - Coach Management"])


# GET /admin/gyms/{gym_id}/coaches
@router.get("", response_model=CoachListResponse)
async def list_coaches(status_filter: str | None = None,  # "active" | "pending" | "suspended"
                       search: str | None = None,
                       db: AsyncSession = Depends(get_session),
                       gym: Gym = Depends(get_admin_gym),
                       ):

    coaches: list[CoachListItem] = []

    rows = (await db.execute(select(GymCoachMembership, Coach, User)
                             .join(Coach, GymCoachMembership.coachID == Coach.coachID)
                             .join(User,  Coach.userID == User.userID)
                             .where(GymCoachMembership.gymID == gym.gymID)
                             )).all()

    for membership, coach, user in rows:
        if search:
            term = search.lower()
            if term not in user.name.lower() and term not in user.email.lower():
                continue
        coaches.append(CoachListItem(
            id=user.userID,
            name=user.name,
            email=user.email,
            phone=user.phone,
            status=membership.status.value,
            hire_date=membership.hire_date,
            invitation_sent=None,
        ))

    # 2. Pending invitations
    invitations = (await db.execute(select(MemberInvitation)
                                    .where(MemberInvitation.gymID  == gym.gymID,
                                           MemberInvitation.status == InvitationStatus.pending,
                                           MemberInvitation.invited_as == "coach",)
                                    )).scalars().all()

    for inv in invitations:
        if search and search.lower() not in inv.email.lower():
            continue
        coaches.append(CoachListItem(
            id=inv.id,
            name="Pending Invitation",
            email=inv.email,
            phone=None,
            status="pending",
            hire_date=None,
            invitation_sent=inv.sent_at,
        ))

    # 3. Apply tab filter
    if status_filter == "active":
        coaches = [c for c in coaches if c.status == "active"]
    elif status_filter == "pending":
        coaches = [c for c in coaches if c.status == "pending"]
    elif status_filter == "suspended":
        coaches = [c for c in coaches if c.status == "suspended"]

    active_count  = sum(1 for c in coaches if c.status == "active")
    pending_count = sum(1 for c in coaches if c.status == "pending")

    return CoachListResponse(
        total=len(coaches),
        active=active_count,
        pending=pending_count,
        coaches=coaches,
    )


# POST /admin/gyms/{gym_id}/coaches/invite
@router.post("/invite", response_model=InviteCoachResponse, status_code=201)
async def invite_member(body: InviteCoachRequest,
                        db: AsyncSession = Depends(get_session),
                        gym: Gym = Depends(get_admin_gym),
                        ):

    # 1. Check the email exists in the app
    existing_user = (await db.execute(
        select(User).where(User.email == body.email)
    )).scalar_one_or_none()

    if not existing_user:
        raise HTTPException(404, "No user found with this email.")

    # 2. Check the user is a coach
    if existing_user.role != UserRole.coach:
        raise HTTPException(400, "This user is not a coach.")

    # 3. Check the user isn't already a coach in this gym
    already_member = (await db.execute(
        select(GymCoachMembership).where(
            GymCoachMembership.coachID == existing_user.userID,
            GymCoachMembership.gymID == gym.gymID,
        )
    )).scalar_one_or_none()

    if already_member:
        raise HTTPException(400, "This coach is already a member of this gym.")

    ## 4. Check for existing pending invitation

    existing_inv = (await db.execute(
        select(MemberInvitation).where(
            MemberInvitation.gymID  == gym.gymID,
            MemberInvitation.email  == body.email,
            MemberInvitation.status == InvitationStatus.pending,
            MemberInvitation.invited_as == "coach",
        )
    )).scalar_one_or_none()

    if existing_inv:
        existing_inv.token      = secrets.token_urlsafe(32)
        existing_inv.sent_at    = datetime.utcnow()
        existing_inv.expires_at = datetime.utcnow() + timedelta(days=3)
        inv = existing_inv
    else:
        inv = MemberInvitation(
            gymID      = gym.gymID,
            email      = body.email,
            invited_as = "coach",
            token      = secrets.token_urlsafe(32),
            status     = InvitationStatus.pending,
            expires_at = datetime.utcnow() + timedelta(days=3),
        )
        db.add(inv)

    await db.commit()
    # await send_invitation_email(body.email, gym.gymName, inv.token)
    await notify_invite(db, body.email, gym.gymName, "coach", gym_id=gym.gymID, token=inv.token)
    return InviteCoachResponse(message="Invitation sent successfully.", email=body.email)


# POST /admin/gyms/{gym_id}/coaches/{coach_id}/suspend
@router.post("/{coach_id}/suspend")
async def suspend_coach(
    coach_id: int,
    db: AsyncSession = Depends(get_session),
    gym: Gym = Depends(get_admin_gym),
):
    membership = (await db.execute(
        select(GymCoachMembership)
        .join(Coach, GymCoachMembership.coachID == Coach.coachID)
        .where(
            GymCoachMembership.gymID == gym.gymID,
            Coach.userID == coach_id,
        )
    )).scalar_one_or_none()

    if not membership:
        raise HTTPException(404, "Coach not found in this gym.")

    membership.status = CoachMembershipStatus.suspended
    await db.commit()
    return {"message": "Coach suspended successfully."}



@router.post("/{member_id}/unsuspend")
async def unsuspend_coach(
    member_id: int,
    db: AsyncSession = Depends(get_session),
    gym: Gym = Depends(get_admin_gym),
):
    membership = (await db.execute(
        select(GymCoachMembership)
        .join(Coach, GymCoachMembership.coachID == Coach.coachID)
        .where(
            GymCoachMembership.gymID == gym.gymID,
            Coach.userID == member_id,
        )
    )).scalar_one_or_none()

    if not membership:
        raise HTTPException(404, "Coach not found in this gym.")

    membership.status = CoachMembershipStatus.active
    await db.commit()
    return {"message": "Client unsuspended successfully."}


# POST /admin/gyms/{gym_id}/coaches/invitations/accept
@router.post("/invitations/accept")
async def accept_coach_invitation(
    token: str,
    db: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    # 1. Find invitation
    inv = (await db.execute(
        select(MemberInvitation).where(
            MemberInvitation.token == token,
            MemberInvitation.status == InvitationStatus.pending,
            MemberInvitation.invited_as == "coach",
        )
    )).scalar_one_or_none()

    if not inv:
        raise HTTPException(404, "Invitation not found or already used.")

    # 2. Check not expired
    if inv.expires_at < datetime.now(timezone.utc):
        raise HTTPException(400, "Invitation has expired.")

    # 3. Check email matches
    if inv.email.lower() != current_user.email.lower():
        raise HTTPException(403, "This invitation is not for your account.")

    # 4. Get coach record
    coach = (await db.execute(
        select(Coach).where(Coach.userID == current_user.userID)
    )).scalar_one_or_none()

    if not coach:
        raise HTTPException(404, "Coach profile not found.")

    # 5. Check not already a coach in this gym
    already = (await db.execute(
        select(GymCoachMembership).where(
            GymCoachMembership.coachID == coach.coachID,
            GymCoachMembership.gymID == inv.gymID,
        )
    )).scalar_one_or_none()

    if already:
        raise HTTPException(400, "Already a coach in this gym.")

    # 6. Create membership — no subscription, no expiry
    membership = GymCoachMembership(
        coachID=coach.coachID,
        gymID=inv.gymID,
        status=CoachMembershipStatus.active,
    )
    db.add(membership)

    # 7. Mark invitation as accepted
    inv.status = InvitationStatus.accepted

    await db.commit()
    return {"message": "Invitation accepted. You are now a coach at this gym!"}


# POST /admin/gyms/{gym_id}/coaches/invitations/decline
@router.post("/invitations/decline")
async def decline_coach_invitation(
    token: str,
    db: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    inv = (await db.execute(
        select(MemberInvitation).where(
            MemberInvitation.token == token,
            MemberInvitation.status == InvitationStatus.pending,
            MemberInvitation.invited_as == "coach",
        )
    )).scalar_one_or_none()

    if not inv:
        raise HTTPException(404, "Invitation not found.")

    if inv.email.lower() != current_user.email.lower():
        raise HTTPException(403, "This invitation is not for your account.")

    inv.status = InvitationStatus.declined
    await db.commit()
    return {"message": "Invitation declined."}


