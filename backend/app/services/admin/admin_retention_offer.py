from datetime import datetime

from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.gym_clients_membership import GymClientMembership, ClientMembershipStatus
from app.models.retention_offer import RetentionOffer, RetentionOfferRecipient
from app.models.client import Client
from app.models.User import User
from app.routers.Admin.churn import predict_churn_risk
from app.schemas.admin.retention_offer import (
    PreviewRequest, MemberPreview, CreateOfferRequest, RetentionDashboardResponse, OfferHistoryItem
)
from app.services.notifications.notification_Utils import send_push_notification ,save_notification

import joblib

model = joblib.load("app/ml/churn_model.pkl")
RISK_ORDER = {"High": 0, "Mid": 1, "Low": 2}

async def get_active_members(db: AsyncSession, gym_id: int):
    today = datetime.now().date()
    result = await db.execute(
        select(GymClientMembership).where(
            GymClientMembership.gymID == gym_id,
            GymClientMembership.status == ClientMembershipStatus.active,
            GymClientMembership.subscription_end >= today,
        )
    )
    return result.scalars().all()

async def get_retention_dashboard_service(db: AsyncSession, gym_id: int):
    members = await get_active_members(db, gym_id)
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


async def preview_members_service(db: AsyncSession, gym_id: int, request: PreviewRequest):
    members = await get_active_members(db, gym_id)

    previews = []
    for m in members:
        risk = await predict_churn_risk(m, db)
        if risk not in RISK_ORDER:
            continue
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
        previews.sort(key=lambda x: RISK_ORDER.get(x.churn_risk, 99))
    elif request.target_type == "lowest_risk":
        previews.sort(key=lambda x: RISK_ORDER.get(x.churn_risk, 99), reverse=True)
    elif request.target_type == "manual_selection":
        previews.sort(key=lambda x: RISK_ORDER.get(x.churn_risk, 99))
        return previews

    if request.number_of_members and request.target_type != "all_members":
        previews = previews[:request.number_of_members]

    return previews

async def create_and_send_offer_service(db: AsyncSession, gym_id: int, request: CreateOfferRequest):
    print("DEBUG: ", request)
    print("number of members: ", len(request.selected_member_ids))
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
    db.add(offer) 
    await db.flush()

    print("DEBUG: ", offer)

    for membership_id in request.selected_member_ids:
        result = await db.execute(select(GymClientMembership).where(
            GymClientMembership.id == membership_id
        ))
        membership = result.scalar_one_or_none()
        risk = f"{await predict_churn_risk(membership, db)} Risk" if membership else "Unknown"
        db.add(RetentionOfferRecipient(
            offer_id=offer.id,
            membership_id=membership_id,
            risk_level=risk,
        ))
        result = await db.execute(
        select(User).join(Client, Client.userID == User.userID)
        .where(Client.clientID == membership.clientID)
        )
        user = result.scalar_one_or_none()
        if not user:
            continue  # or handle missing user
        title = f"You've an offer from your gym!"
        body = f"the offer: '{request.title}' is available for you.Go to gym management to redeem."
        data = {
            "gym_id": str(gym_id) if gym_id else "",
        }
        await save_notification(db, user.userID, title, body, "gym_offer", data)
        await send_push_notification(db, user.userID, title, body, data)

    # print("Debug from send offer: ", request.selected_member_ids)
    await db.commit()
    await db.refresh(offer)
    return {
        "message": f"Offer '{request.title}' sent to {len(request.selected_member_ids)} members successfully",
        "offer_id": offer.id,
        "sent_to": len(request.selected_member_ids),
    }
