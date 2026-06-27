from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from app.database import get_session
from app.dependencies.auth import get_current_user
from app.models.User import User
from app.schemas.admin.retention_offer import (
    PreviewRequest, MemberPreview, CreateOfferRequest, RetentionDashboardResponse, OfferHistoryItem
)

from app.services.admin.admin_retention_offer import (
    get_retention_dashboard_service,
    preview_members_service, create_and_send_offer_service
)

import joblib

model = joblib.load("app/ml/churn_model.pkl") 
router = APIRouter(prefix="/retention", tags=["Retention Offer"])
RISK_ORDER = {"High": 0, "Mid": 1, "Low": 2}


## 1- Dashboard
@router.get("/dashboard/{gym_id}", response_model=RetentionDashboardResponse)
async def get_retention_dashboard(gym_id: int, db: AsyncSession = Depends(get_session), current_user: User = Depends(get_current_user)):
    return await get_retention_dashboard_service(db, gym_id)



@router.post("/preview/{gym_id}", response_model=List[MemberPreview])
async def preview_members(gym_id: int, request: PreviewRequest, db: AsyncSession = Depends(get_session), current_user=Depends(get_current_user)):
    return await preview_members_service(db, gym_id, request)

@router.post("/send/{gym_id}")
async def create_and_send_offer(gym_id: int, request: CreateOfferRequest, db: AsyncSession = Depends(get_session), current_user=Depends(get_current_user)):
    return await create_and_send_offer_service(db, gym_id, request)
