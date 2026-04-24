# app/models/user.py
#example only , willl be removed later
from sqlalchemy import Column, Integer, String
from app.database import Base

class User(Base):
    __tablename__ = "users"

    userID   = Column("userID", Integer, primary_key=True, index=True)  # ← explicit column name
    email    = Column(String, unique=True, nullable=False)
    password = Column(String, nullable=False)
    name     = Column(String, nullable=False)
    role     = Column(String, nullable=False)

    __mapper_args__ = {
        "polymorphic_on": role,
        "polymorphic_identity": "user"
    }