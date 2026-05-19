from sqlalchemy import Column, Integer, ForeignKey, DateTime
from sqlalchemy.sql import func
from app.database import Base
from sqlalchemy import Date  # You'll need to import this
from sqlalchemy import String  # For day_of_week

class Attendance(Base):
    __tablename__ = "attendance"

    id           = Column(Integer, primary_key=True, index=True)
    membershipID = Column(Integer, ForeignKey("gym_client_memberships.id"), nullable=False)
    checked_in   = Column(DateTime(timezone=True), server_default=func.now())

    ## New cells
    # # Pre-indexed fields — populated by the attendance router before insert
    clientID = Column(Integer, ForeignKey("clients.clientID"), nullable=True)
    gymID = Column(Integer, ForeignKey("gyms.gymID"), nullable=True)
    check_in_hour = Column(Integer,    nullable=True)   # 0–23  (gym local time)
    check_in_date = Column(Date,       nullable=True)   # calendar date (gym local tz)
    day_of_week   = Column(String(10), nullable=True)   # "monday" … "sunday"