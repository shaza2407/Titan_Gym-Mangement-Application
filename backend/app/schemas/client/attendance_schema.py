# schemas/attendance_schema.py
import string

from pydantic import BaseModel
from typing import Optional
from datetime import datetime, date
from typing import List

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
    day_of_week: Optional[str] = None


class CheckinRecord(BaseModel):
    id:         int
    checked_in: datetime
    day_of_week: Optional[str] = None
    
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
    # new
    favorite_checkin_hour: Optional[int] = None
    most_active_day: Optional[str] = None
    total_gyms_visited: Optional[int] = None



class AttendanceStatsResponse(BaseModel):
    today_total: int
    this_week: int

class QRCodeResponse(BaseModel):
    gym_id: int
    qr_identifier: str
    gym_name: str

class CheckinRequest(BaseModel):
    qr_code: str

class DayAttendance(BaseModel):
    day: str
    count: int

class WeeklyAttendanceResponse(BaseModel):
    week_start: str
    days: list[DayAttendance]