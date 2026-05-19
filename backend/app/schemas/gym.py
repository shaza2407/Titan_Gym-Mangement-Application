from pydantic import BaseModel, Field
from typing import Optional


class GymBase(BaseModel):
    gymName: str = Field(..., example="FitZone")
    subscriptionPrice: float = Field(..., example=199.99)
    yearlySubscriptionPrice: float = Field(..., example=999.99)
    location: str = Field(..., example="123 Main St, Cairo")
    gymType: str = Field(..., example="mixed")          # males, females, mixed
    openingHours: str = Field(..., example="06:00")
    closingHours: str = Field(..., example="23:00")


class GymCreate(GymBase):
    pass


class GymUpdate(BaseModel):
    gymName: Optional[str] = None
    subscriptionPrice: Optional[float] = None
    yearlySubscriptionPrice: Optional[float] = None
    location: Optional[str] = None
    gymType: Optional[str] = None
    openingHours: Optional[str] = None
    closingHours: Optional[str] = None


class GymResponse(GymBase):
    gymID: int
    adminID: int   
    QRCode:  Optional[str] = None         

    class Config:
        from_attributes = True

class GymDashboardStats(BaseModel):
    gymID: int
    gymName: str
    totalMembers: int
    activeSubscriptions: int
    todayAttendance: int
    monthlyRevenue: float

    class Config:
        from_attributes = True