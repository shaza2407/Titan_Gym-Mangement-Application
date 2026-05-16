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