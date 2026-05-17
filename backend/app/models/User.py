# app/models/user.py
from sqlalchemy import Column, Integer, String, Boolean, DateTime
from app.database import Base

class User(Base):
    __tablename__ = "users"

    userID = Column("userID", Integer, primary_key=True, index=True) 
    email = Column(String, unique=True, nullable=False)
    password = Column(String, nullable=False)
    name = Column(String, nullable=False)
    role = Column(String, nullable=False)
    phone = Column(String, nullable=True)
    is_verified = Column(Boolean, default=False)
    reset_token     = Column(String, nullable=True)      # ✅ now a real column
    reset_token_exp = Column(DateTime, nullable=True)
