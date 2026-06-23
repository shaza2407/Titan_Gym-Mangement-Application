from sqlalchemy import Column, Integer, ForeignKey, DateTime
from sqlalchemy.sql import func
from app.database import Base
from sqlalchemy import Date  # You'll need to import this
from sqlalchemy import String  # For day_of_week

class Attendance(Base):
    __tablename__ = "attendance"

    id           = Column(Integer, primary_key=True, index=True)
    membershipID = Column(Integer, ForeignKey("gym_client_memberships.id" ,ondelete="CASCADE"), nullable=False)
    checked_in = Column(DateTime(timezone=False), nullable=True)
    day_of_week   = Column(String(10), nullable=True)   # "monday" … "sunday"