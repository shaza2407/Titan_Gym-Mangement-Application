from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class CheckinStatusResponse(BaseModel):
    can_checkin:       bool
    reason:            str          # "ok" | "not_connected" | "suspended" | "expired" | "already_checked_in"
    membershipID:      Optional[int] = None
    subscription:      Optional[str] = None
    subscription_end:  Optional[str] = None
    status:            Optional[str] = None

class CheckinResponse(BaseModel):
    message:    str
    checked_in: str

class CheckinRecord(BaseModel):
    id:         int
    checked_in: datetime

    class Config:
        from_attributes = True

class CheckinHistoryResponse(BaseModel):
    checkins: list[CheckinRecord]


class DashboardStatsResponse(BaseModel):
    total_visits:      int
    days_this_week:    int
    current_streak:    int
    subscription:      Optional[str] = None
    subscription_end:  Optional[str] = None  # expiration check
    days_remaining:    Optional[int] = None
    membership_status: Optional[str] = None  # "active" | "suspended"
    gym_name:          Optional[str] = None
    name:              Optional[str] = None   # client name
    