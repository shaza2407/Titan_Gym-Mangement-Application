from sqlalchemy import Column,Integer,String,Date,Time,ForeignKey, Enum as SQLEnum
from app.database import Base
from sqlalchemy.orm import relationship

import enum

class RequestStatus(str,enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class ClassSession(Base):
    __tablename__= "class_sessions"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    date = Column(Date,nullable=False)
    start_time = Column(Time,nullable=False)

    # foreign keys
    # gym_id = Column(Integer,ForeignKey("gyms.id"),nulable=False)
    coach_id = Column(Integer, ForeignKey("coaches.coachID"), nullable=False)

    current_students = Column(Integer,default=0)
    max_students = Column(Integer, nullable=False)


class ClassRequest(Base):
    __tablename__ = "class_requests"

    id = Column(Integer, primary_key=True, index=True)
    class_type = Column(String, nullable=False)
    requested_date = Column(Date,nullable=False)
    requested_time = Column(Time,nullable=False)

    status = Column(SQLEnum(RequestStatus), default=RequestStatus.PENDING)

    # gym_id = Column(Integer, ForeignKey("gyms.id"), nullable=False)
    coach_id = Column(Integer, ForeignKey("coaches.coachID"), nullable=False)
