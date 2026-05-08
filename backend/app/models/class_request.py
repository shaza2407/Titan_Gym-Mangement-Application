from sqlalchemy import Column,Integer,String,Date,Time,ForeignKey, Enum as SQLEnum
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
    # gym_id = Column(Integer, ForeignKey("gyms.id"), nullable=False)
    coach_id = Column(Integer, ForeignKey("coaches.coachID"), nullable=False)
    
    class_name = Column(String, nullable=False)
    gym_location = Column(String, nullable=False)
    requested_date = Column(Date,nullable=False)
    requested_time = Column(Time,nullable=False)
    duration = Column(Integer, nullable=False)

    max_capacity = Column(Integer, nullable=False)
    reason_for_request = Column(String, nullable=True)

    status = Column(SQLEnum(RequestStatus), default=RequestStatus.PENDING)

    created_at = Column(DateTime(timezone=True),default=lambda: datetime.now(timezone.utc))