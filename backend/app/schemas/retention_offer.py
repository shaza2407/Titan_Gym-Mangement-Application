from pydantic import BaseModel
from typing import Optional, List
from datetime import date
from enum import Enum


class OfferType(str, Enum):
    discount = "discount"
    supplements = "supplements"
    free_sessions = "free_sessions"
    membership_upgrade = "membership_upgrade"


class TargetType(str, Enum):
    highest_risk = "highest_risk"
    lowest_risk = "lowest_risk"
    all_members = "all_members"
    manual_selection = "manual_selection"

## 1- Preview request
class PreviewRequest(BaseModel):
    target_type: TargetType
    number_of_members: Optional[int] = None

## 2- Member shown in preview list
class MemberPreview(BaseModel):
    membershipID: int
    clientID: int
    name: str
    email: str
    churn_risk: str

## 3- Create & send offer request
class CreateOfferRequest(BaseModel):
    title: str
    offer_type: OfferType
    description: Optional[str] = None
    benefit: str
    valid_until: Optional[date] = None
    target_type: TargetType
    selected_member_ids: List[int]


## 4- Offer history item
class OfferHistoryItem(BaseModel):
    id: int
    title: str
    offer_type: OfferType
    target_type: TargetType
    number_of_members: int
    created_at: str

## 5-Dashboard response
class RetentionDashboardResponse(BaseModel):
    high_risk_count: int
    mid_risk_count: int
    offers_sent: int
    ai_insight: str
    offer_history: List[OfferHistoryItem]