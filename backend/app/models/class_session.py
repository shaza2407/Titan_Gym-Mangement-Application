# app/models/class_session.py

from sqlalchemy import Column, Integer, String, Date, Time, ForeignKey, Boolean
from app.database import Base


class ClassSession(Base):
    __tablename__ = "class_sessions"

    id              = Column(Integer, primary_key=True, index=True)
    title           = Column(String, nullable=False)
    day_of_week     = Column(String(10), nullable=True)   # "monday" … "sunday" for recurring
    date            = Column(Date, nullable=True)          # for one-time classes
    start_time      = Column(Time, nullable=False)
    duration        = Column(Integer, nullable=False, default=45)  # minutes
    is_recurring    = Column(Boolean, default=True)        # True = weekly, False = one-time

    # foreign keys
    gymID           = Column(Integer, ForeignKey("gyms.gymID" ,ondelete="CASCADE"), nullable=True)
    coach_id        = Column(Integer, ForeignKey("coaches.coachID" ,ondelete="CASCADE"), nullable=False)

    current_clients = Column(Integer, default=0)
    max_clients     = Column(Integer, nullable=False)