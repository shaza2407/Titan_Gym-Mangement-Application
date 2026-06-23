# models/Announcement.py
from sqlalchemy import Column, Integer, ForeignKey, DateTime, String
from sqlalchemy.sql import func
from app.database import Base

class Announcement(Base):
    __tablename__ = "announcements"

    announce_id = Column(Integer, primary_key=True, index=True)
    gymID       = Column(Integer, ForeignKey("gyms.gymID"), nullable=False)
    title       = Column(String(255), nullable=False)
    content     = Column(String(1000), nullable=False)
    reciever    = Column(String(50), nullable=False, server_default='Clients and Coaches')  
    created_at  = Column(DateTime(timezone=False), server_default=func.now(), nullable=False)