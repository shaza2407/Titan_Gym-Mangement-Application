from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from datetime import datetime, timezone

from app.database import get_session
from app.dependencies.auth import get_current_user
from app.models.gym_clients_membership import GymClientMembership, ClientMembershipStatus
from app.models.retention_offer import RetentionOffer
from app.models.client import Client
from app.models.User import User
# from churn import predict_churn_risk
from app.routers.Admin.churn import predict_churn_risk
from app.schemas.admin.retention_offer import (
    PreviewRequest, MemberPreview, CreateOfferRequest, RetentionDashboardResponse, OfferHistoryItem
)

router = APIRouter(prefix="/retention", tags=["Retention Offer"])
RISK_ORDER = {"High": 0, "Mid": 1, "Low": 2}

## helper functions
async def get_active_members(gym_id: int, db: AsyncSession):
    today = datetime.now(timezone.utc).date()
    result = await db.execute(
        select(GymClientMembership).where(
            GymClientMembership.gymID == gym_id,
            GymClientMembership.status == ClientMembershipStatus.active,
            GymClientMembership.subscription_end >= today,
        )
    )
    return result.scalars().all()


## 1- Dashboard
@router.get("/dashboard/{gym_id}", response_model=RetentionDashboardResponse)
async def get_retention_dashboard(gym_id: int, db: AsyncSession = Depends(get_session), current_user: User = Depends(get_current_user)):
    members = await get_active_members(gym_id, db)
    high_count = 0
    mid_count = 0
    for membership in members:
        risk = await predict_churn_risk(membership, db)
        if risk == "High":
            high_count += 1
        elif risk == "Mid":
            mid_count += 1

    result = await db.execute(
        select(RetentionOffer).where(RetentionOffer.gymId == gym_id)
        .order_by(RetentionOffer.created_at.desc()).limit(10)
    )
    offers = result.scalars().all()

    total_number_of_members = sum(o.number_of_members for o in offers)

    history = [
        OfferHistoryItem(
            id=o.id,
            title=o.title,
            offer_type=o.offer_type,
            target_type=o.target_type,
            number_of_members=o.number_of_members,
            created_at=o.created_at.strftime("%b %d, %Y")
        )
        for o in offers
    ]

    if high_count == 0:
        insight = "Great news! No members are at high churn risk this month. Keep up the engagement."
    else:
        insight = (
            f"Our ML model identifies {high_count} member(s) at high risk of churning this month. "
            f"The primary factors are low attendance and expiring subscriptions. "
            f"Create targeted retention offers below."
        )

    return RetentionDashboardResponse(
        high_risk_count=high_count,
        mid_risk_count=mid_count,
        offers_sent=total_number_of_members,
        ai_insight=insight,
        offer_history=history,
        total_active_members=len(members),
    )



@router.post("/preview/{gym_id}", response_model=List[MemberPreview])
async def preview_members(gym_id: int, request: PreviewRequest, db: AsyncSession = Depends(get_session), current_user=Depends(get_current_user)):
    members = await get_active_members(gym_id, db)

    previews = []
    for m in members:
        risk = await predict_churn_risk(m, db)
        client_result = await db.execute(select(Client).where(Client.clientID == m.clientID))
        client = client_result.scalar_one_or_none()
        if not client:
            continue

        user_result = await db.execute(select(User).where(User.userID == client.userID))
        user = user_result.scalar_one_or_none()
        if not user:
            continue

        previews.append(MemberPreview(
            membershipID=m.id,
            clientID=m.clientID,
            name=user.name,
            email=user.email,
            churn_risk=risk,
        ))


    ## {m1: r1, m2: r2, m3: r3...}
    if request.target_type == "highest_risk":
        previews.sort(key=lambda x: RISK_ORDER[x.churn_risk])
    elif request.target_type == "lowest_risk":
        previews.sort(key=lambda x: RISK_ORDER[x.churn_risk], reverse=True)
    elif request.target_type == "manual_selection":
        previews.sort(key=lambda x: RISK_ORDER[x.churn_risk])  # show all sorted
        return previews

    if request.number_of_members and request.target_type != "all_members":
        previews = previews[:request.number_of_members]

    return previews

@router.post("/send/{gym_id}")
async def create_and_send_offer(gym_id: int, request: CreateOfferRequest, db: AsyncSession = Depends(get_session), current_user=Depends(get_current_user)):
    if not request.selected_member_ids:
        raise HTTPException(status_code=400, detail="No members selected")
    offer = RetentionOffer(
        gymId = gym_id,
        title = request.title,
        offer_type = request.offer_type,
        description = request.description,
        benefit = request.benefit,
        valid_until = request.valid_until,
        target_type = request.target_type,
        number_of_members = len(request.selected_member_ids),
    )
    db.add(offer) ## We need to send notification here
    await db.commit()
    await db.refresh(offer)
    return {
        "message": f"Offer '{request.title}' sent to {len(request.selected_member_ids)} members successfully",
        "offer_id": offer.id,
        "sent_to": len(request.selected_member_ids),
    }

