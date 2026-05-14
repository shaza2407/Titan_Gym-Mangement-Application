
from pydantic import BaseModel, EmailStr
from datetime import date,time,datetime
from typing import Optional

class ClassSessionResponse(BaseModel):
    id: int
    class_id: int
    coach_id: int
    # start_time: datetime
    # end_time: datetime
    # status: RequestStatus

    class Config:
        orm_mode = True

class DashboardStatsResponse(BaseModel):
    weekly_classes: int
    total_clients: int
    # active_gyms: int


class ScheduleStatsResponse(BaseModel):
    weekly_classes:int
    total_clients:int
    pending_requests: int


class MyClassesResponse(BaseModel):
    title:str
    gym_name:str
    schedule_summary:str  # "Mon, Wed, Fri - 7:00 AM"


class CreateClassRequestPayload(BaseModel):
    class_name:str
    gym_location: Optional[str] = None
    requested_date:date
    requested_time:time
    duration:int
    max_capacity:int
    reason:Optional[str] = None
    

class ClassRequestResponse(BaseModel):
    id: int
    class_name: str
    requested_date: date
    requested_time: time
    gym_location: str
    status: str       
    reason_for_request: Optional[str]
    created_at: datetime

    class Config:
        orm_mode = True


class InviteCoachRequest(BaseModel):
    email: EmailStr

class InviteCoachResponse(BaseModel):
    message: str
    email:   str


class CoachListItem(BaseModel):
    id: int
    name: str
    email: str
    phone: Optional[str] = None
    status: str           # "active" | "pending" | "suspended"
    hire_date: Optional[datetime] = None
    invitation_sent: Optional[datetime] = None

    class Config:
        from_attributes = True

class CoachListResponse(BaseModel):
    total:   int
    active:  int
    pending: int
    coaches: list[CoachListItem]