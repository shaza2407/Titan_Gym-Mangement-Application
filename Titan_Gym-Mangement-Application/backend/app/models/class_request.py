# app/models/class_request.py

from sqlalchemy import Boolean, Column, Integer, String, Date, Time, ForeignKey, Enum as SQLEnum, DateTime
from app.database import Base
from datetime import datetime, timezone
import enum


class RequestStatus(str, enum.Enum):
    PENDING  = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class ClassRequest(Base):
    __tablename__ = "class_requests"

    id       = Column(Integer, primary_key=True, index=True)
    gymID    = Column(Integer, ForeignKey("gyms.gymID"), nullable=False)  # ← not nullable
    coach_id = Column(Integer, ForeignKey("coaches.coachID"), nullable=False)

    class_name = Column(String, nullable=False)

    is_recurring   = Column(Boolean, default=True)
    day_of_week    = Column(String(10), nullable=True)   # for recurring
    requested_date = Column(Date, nullable=True)          # for one-time only
    requested_time = Column(Time, nullable=False)
    duration       = Column(Integer, nullable=False)

    max_capacity        = Column(Integer, nullable=False)
    reason_for_request  = Column(String, nullable=True)

    status     = Column(SQLEnum(RequestStatus), default=RequestStatus.PENDING)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))