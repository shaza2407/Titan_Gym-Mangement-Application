"""
app/models/gym_machine.py
─────────────────────────
Stores gyms and their machines.

Tables:
  gyms          – gym locations
  gym_machines  – machines per gym with validity status
"""

from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Text, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class Gym(Base):
    __tablename__ = "gyms"

    gymID       = Column("gymID",     Integer, primary_key=True, index=True)
    name        = Column(String(150), nullable=False)
    location    = Column(String(255), nullable=True)
    is_active   = Column(Boolean,     default=True, nullable=False)
    created_at  = Column(DateTime(timezone=True), server_default=func.now())

    # relationships
    machines    = relationship("GymMachine", back_populates="gym", cascade="all, delete-orphan")


class GymMachine(Base):
    __tablename__ = "gym_machines"

    machineID       = Column("machineID",   Integer, primary_key=True, index=True)
    gymID           = Column("gymID",       Integer, ForeignKey("gyms.gymID"), nullable=False)
    name            = Column(String(150),   nullable=False)          # e.g. "Treadmill", "Leg Press"
    category        = Column(String(100),   nullable=True)           # e.g. "Cardio", "Strength"
    description     = Column(Text,          nullable=True)
    muscle_groups   = Column(String(255),   nullable=True)           # comma-separated: "quads,hamstrings"
    is_valid        = Column(Boolean,       default=True, nullable=False)  # working / out-of-service
    maintenance_note= Column(Text,          nullable=True)           # reason if not valid
    created_at      = Column(DateTime(timezone=True), server_default=func.now())
    updated_at      = Column(DateTime(timezone=True), onupdate=func.now())

    # relationships
    gym = relationship("Gym", back_populates="machines")