from sqlalchemy import Column, Integer, ForeignKey, DateTime
from sqlalchemy.sql import func
from app.database import Base
from sqlalchemy import Date 
from sqlalchemy import String  

class Attendance(Base):
    __tablename__ = "attendance"

    id         = Column(Integer, primary_key=True, index=True)
    gymID      = Column(Integer, ForeignKey("gyms.gymID", ondelete="CASCADE"), nullable=False)
    clientID   = Column(Integer, ForeignKey("clients.clientID", ondelete="CASCADE"), nullable=False)
    checked_in = Column(DateTime(), nullable=True)
    day_of_week = Column(String(10), nullable=True)