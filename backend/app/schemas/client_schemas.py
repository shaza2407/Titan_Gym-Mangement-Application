from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime, date

class InviteClientRequest(BaseModel):
    email: str
    subscription_type: str = "monthly"   # "monthly" | "yearly"
    subscription_months: int = 1 

class InviteClientResponse(BaseModel):
    message: str
    email: str


class ClientListItem(BaseModel):
    id: int
    name: str
    email: str
    phone: Optional[str] = None
    status: str           # "active" | "pending" | "expired"
    subscription: Optional[str] = None
    subscription_end: Optional[datetime] = None
    visits: Optional[int] = None
    # churn_risk: Optional[str]
    joined: Optional[datetime] = None
    invitation_sent: Optional[datetime] = None

    class Config:
        from_attributes = True

class ClientListResponse(BaseModel):
    total: int
    active: int
    pending: int
    expired: int
    members: list[ClientListItem]




