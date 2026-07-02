# app/schemas/coach_schemas.py

from pydantic import BaseModel, EmailStr ,field_validator
from datetime import date, time, datetime
import datetime as dt
from typing import Optional, List


# ── Dashboard ─────────────────────────────────────────────────────────────────

class CoachDashboardStatsResponse(BaseModel):
    weekly_classes:  int
    total_clients:  int
    active_gyms:     int


class CoachUpcomingClassResponse(BaseModel):
    id:              int
    title:           str
    day_of_week:     Optional[str] = None
    date:            Optional[dt.date] = None # type: ignore
    start_time:      time
    duration:        int
    gym_name:        Optional[str] = None
    current_clients: int
    max_clients:     int

    class Config:
        from_attributes = True


# ── Schedule ──────────────────────────────────────────────────────────────────

class CoachScheduleStatsResponse(BaseModel):
    weekly_classes:   int
    total_clients:   int
    pending_requests: int


class CoachClassResponse(BaseModel):
    id:              int
    title:           str
    day_of_week:     Optional[str] = None
    date:            Optional[dt.date] = None # type: ignore
    start_time:      time
    duration:        int
    is_recurring:    bool
    gym_name:        Optional[str] = None
    current_clients: int
    max_clients:     int

    class Config:
        from_attributes = True


class CoachWeekDay(BaseModel):
    day:     str
    label:   str
    classes: list = []


# ── Class Requests ────────────────────────────────────────────────────────────

class CreateClassRequestPayload(BaseModel):
    class_name:     str
    gym_id:         int
    is_recurring:   bool = True
    day_of_week:    Optional[str]  = None
    requested_date: Optional[dt.date] = None
    requested_time: time
    duration:       int
    max_capacity:   int
    reason:         Optional[str]  = None


class ClassRequestResponse(BaseModel):
    id:                 int
    coach_id:           int
    gymID:              int
    class_name:         str
    is_recurring:       bool
    day_of_week:        Optional[str]  = None
    requested_date:     Optional[date] = None
    requested_time:     time
    duration:           int
    max_capacity:       int
    reason_for_request: Optional[str]  = None
    status:             str
    created_at:         datetime

    class Config:
        from_attributes = True


# ── Profile ───────────────────────────────────────────────────────────────────

class CoachProfileUpdate(BaseModel):
    name:             Optional[str]  = None
    phone:            Optional[str]  = None
    bio:              Optional[str]  = None
    specializations:  Optional[List[str]] = None
    certifications:   Optional[str]  = None
    years_experience: Optional[int]  = None
    date_of_birth:    Optional[date] = None
 
    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v):
        if v is None:
            return v
        if not v.startswith('01') or len(v) != 11 or not v.isdigit():
            raise ValueError('Phone must be 11 digits and start with 01')
        return v

class CoachProfileResponse(BaseModel):
    userID:           int
    coachID:          int
    name:             str
    email:            str
    phone:            Optional[str]  = None
    bio:              Optional[str]  = None
    specializations:  Optional[List[str]] = None
    certifications:   Optional[str]  = None
    years_experience: Optional[int]  = None
    date_of_birth:    Optional[date] = None

    class Config:
        from_attributes = True


# ── Admin lists ───────────────────────────────────────────────────────────────

class InviteCoachRequest(BaseModel):
    email: EmailStr

class InviteCoachResponse(BaseModel):
    message: str
    email:   str

class CoachListItem(BaseModel):
    id:              int
    name:            str
    email:           str
    phone:           Optional[str]   = None
    status:          str
    hire_date:       Optional[datetime] = None
    invitation_sent: Optional[datetime] = None

    class Config:
        from_attributes = True

class CoachListResponse(BaseModel):
    total:   int
    active:  int
    pending: int
    coaches: list[CoachListItem]


class CoachGymLookUpResponse(BaseModel):
    id: int
    name: str
    status: str

    class Config:
        from_attributes = True


# ── Coach Gyms ───
class CoachGymResponse(BaseModel):
    gym_id: int
    name: str
    address: Optional[str] = None
    status: str
    clients_count: int
    classes_count: int
    next_class: Optional[CoachUpcomingClassResponse] = None
    
    class Config:
        from_attributes = True