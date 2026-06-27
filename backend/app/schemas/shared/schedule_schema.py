# app/schemas/schedule_schema.py

from pydantic import BaseModel, ConfigDict
from typing import Optional, List
from datetime import date as DateType, time, datetime


# ── Shared ────────────────────────────────────────────────────────────────────

class ClassSessionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id:              int
    title:           str
    day_of_week:     Optional[str] = None
    date:            Optional[DateType] = None
    start_time:      time
    duration:        int
    is_recurring:    bool
    gymID:           int = None
    coach_id:        int
    coach_name:      Optional[str] = None
    current_clients: int
    max_clients:     int


class ClassRequestResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id:                 int
    coach_id:           int
    coach_name:         Optional[str] = None
    gymID:              Optional[int] = None
    class_name:         str
    gym_location:       str
    is_recurring:       bool
    day_of_week:        Optional[str] = None
    requested_date:     Optional[DateType] = None
    requested_time:     time
    duration:           int
    max_capacity:       int
    reason_for_request: Optional[str] = None
    status:             str
    created_at:         datetime


# ── Admin ─────────────────────────────────────────────────────────────────────

class CreateClassRequest(BaseModel):
    title:        str
    coach_id:     int
    day_of_week:  Optional[str]      = None  # for recurring only
    date:         Optional[DateType] = None  # for one-time only
    start_time:   time
    duration:     int = 45
    max_clients:  int
    is_recurring: bool = True


class AdminScheduleStatsResponse(BaseModel):
    total_classes:    int
    total_enrolled:   int
    total_coaches:    int
    pending_requests: int


class EditClassRequest(BaseModel):
    title:        Optional[str]      = None
    coach_id:     Optional[int]      = None
    day_of_week:  Optional[str]      = None
    date:         Optional[DateType] = None
    start_time:   Optional[time]     = None
    duration:     Optional[int]      = None
    max_clients:  Optional[int]      = None
    is_recurring: Optional[bool]     = None


# ── Client ────────────────────────────────────────────────────────────────────

class EnrollmentResponse(BaseModel):
    message:    str
    session_id: int
    clientID:   int


class ClientScheduleStatsResponse(BaseModel):
    enrolled:     int
    upcoming:     int
    minutes_week: int


class ClientClassResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id:              int
    title:           str
    coach_name:      Optional[str] = None
    day_of_week:     Optional[str] = None
    date:            Optional[DateType] = None
    start_time:      time
    duration:        int
    is_recurring:    bool
    current_clients: int
    max_clients:     int
    is_enrolled:     bool = False
    is_full:         bool = False
    next_date:       Optional[DateType] = None


class WeeklyScheduleDay(BaseModel):
    day:     str
    classes: List[ClientClassResponse] = []


# ── Coach request ─────────────────────────────────────────────────────────────

class CreateClassRequestPayload(BaseModel):
    class_name:     str
    gym_location:   Optional[str]      = None
    is_recurring:   bool               = True
    day_of_week:    Optional[str]      = None
    requested_date: Optional[DateType] = None
    requested_time: time
    duration:       int
    max_capacity:   int
    reason:         Optional[str]      = None