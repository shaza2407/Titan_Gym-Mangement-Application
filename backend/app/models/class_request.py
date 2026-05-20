from sqlalchemy import Boolean, Column,Integer,String,Date,Time,ForeignKey, Enum as SQLEnum
from app.database import Base
from sqlalchemy import DateTime
from datetime import datetime,timezone

import enum

class RequestStatus(str,enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"



class ClassRequest(Base):
    __tablename__ = "class_requests"

    id = Column(Integer, primary_key=True, index=True)
    gymID = Column(Integer, ForeignKey("gyms.gymID"), nullable=True)
    coach_id = Column(Integer, ForeignKey("coaches.coachID"), nullable=False)
    
    class_name = Column(String, nullable=False)
    gym_location = Column(String, nullable=False)
    
    is_recurring    = Column(Boolean, default=True)          # True = weekly, False = one-time
    day_of_week     = Column(String(10), nullable=True)      # for recurring
    requested_date = Column(Date,nullable=False)
    requested_time = Column(Time,nullable=False)
    duration = Column(Integer, nullable=False)

    max_capacity = Column(Integer, nullable=False)
    reason_for_request = Column(String, nullable=True)

    status = Column(SQLEnum(RequestStatus), default=RequestStatus.PENDING)

    created_at = Column(DateTime(timezone=True),default=lambda: datetime.now(timezone.utc))