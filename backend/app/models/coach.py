# app/models/coach.py

from app.database import Base
from sqlalchemy import Column, Integer, String, ForeignKey, Text, Date

class Coach(Base):
    __tablename__ = "coaches"

    coachID          = Column("coachID", Integer, primary_key=True, index=True)
    userID           = Column("userID", Integer, ForeignKey("users.userID"), nullable=False)
    bio              = Column(Text, nullable=True)
    specializations  = Column(String, nullable=True)  # comma-separated
    certifications   = Column(String, nullable=True)
    years_experience = Column(Integer, nullable=True)
    date_of_birth    = Column(Date, nullable=True)