# app/models/class_enrollment.py

from sqlalchemy import Column, Integer, ForeignKey, DateTime, UniqueConstraint
from sqlalchemy.sql import func
from app.database import Base


class ClassEnrollment(Base):
    __tablename__ = "class_enrollments"

    id         = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("class_sessions.id"), nullable=False)
    clientID   = Column(Integer, ForeignKey("clients.clientID"), nullable=False)
    enrolled_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint('session_id', 'clientID', name='unique_enrollment'),
    )