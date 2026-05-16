from sqlalchemy import Column, Integer, ForeignKey, DateTime
from sqlalchemy.sql import func
from app.database import Base

class Attendance(Base):
    __tablename__ = "attendance"

    id           = Column(Integer, primary_key=True, index=True)
    membershipID = Column(Integer, ForeignKey("gym_client_memberships.id"), nullable=False)
    checked_in   = Column(DateTime(timezone=True), server_default=func.now())
    
