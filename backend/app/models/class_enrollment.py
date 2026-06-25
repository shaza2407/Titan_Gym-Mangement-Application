# app/models/class_enrollment.py

from sqlalchemy import Column, Integer, ForeignKey, DateTime, Date, UniqueConstraint
from sqlalchemy.sql import func
from app.database import Base


class ClassEnrollment(Base):
    __tablename__ = "class_enrollments"

    id          = Column(Integer, primary_key=True, index=True)
    session_id  = Column(Integer, ForeignKey("class_sessions.id" ,ondelete="CASCADE"), nullable=False)
    clientID    = Column(Integer, ForeignKey("clients.clientID"  ,ondelete="CASCADE"), nullable=False)
    class_date  = Column(Date, nullable=False)  # specific occurrence date
    enrolled_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint('session_id', 'clientID', 'class_date',
                         name='unique_enrollment_per_date'),
    )