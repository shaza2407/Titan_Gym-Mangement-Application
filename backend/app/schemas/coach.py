
from pydantic import BaseModel


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
    total_students: int
    # active_gyms: int
    pending_requests: int