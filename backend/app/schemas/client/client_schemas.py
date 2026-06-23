from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from pydantic import field_validator

class InviteClientRequest(BaseModel):
    email: str
    subscription_type: str = "monthly"   # "monthly" | "yearly"
    subscription_months: int = 1 
    subscription_price: int

    @field_validator('subscription_price')
    @classmethod
    def price_must_be_positive(cls, v):
        if v <= 0:
            raise ValueError('subscription_price must be greater than 0')
        return v
    
    
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




