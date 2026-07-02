"""
app/models/achievement.py
──────────────────────────
Table:
  achievements – static badge catalog (admin-managed, all 5 levels per chain)

Related models (separate files):
  client_achievement.py – per-client progress & unlock status
  check_in.py           – gym check-in log

Design:
  • Each achievement chain (Gym Rat, Monthly Champion, …) has 5 rows:
    bronze → silver → gold → platinum → diamond.
  • prerequisite_key: the key of the previous level that must be unlocked
    before this row becomes visible/active.
  • Only one level per chain is "active" at a time for a given client.
  • Progress carries forward across levels (Silver starts at Bronze's final value).
"""

import enum
from sqlalchemy import (
    Column, Integer, String, Boolean, Text,
    DateTime, Enum as SAEnum,
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


# ── Enums ─────────────────────────────────────────────────────────────────────

class AchievementCategory(str, enum.Enum):
    CHECKIN   = "CHECKIN"
    STREAK    = "STREAK"
    CLASS     = "CLASS"
    MILESTONE = "MILESTONE"
    TRAINING  = "TRAINING"


class AchievementDifficulty(str, enum.Enum):
    BRONZE   = "BRONZE"
    SILVER   = "SILVER"
    GOLD     = "GOLD"
    PLATINUM = "PLATINUM"
    DIAMOND  = "DIAMOND"


# ── Static achievement catalog ────────────────────────────────────────────────

class Achievement(Base):
    __tablename__ = "achievements"

    achievementID    = Column("achievementID", Integer, primary_key=True, index=True)

    # Identity
    key              = Column(String(100), unique=True, nullable=False, index=True)
    # e.g. "gym_rat_bronze", "gym_rat_silver"
    chain_key        = Column(String(80),  nullable=False, index=True)
    # e.g. "gym_rat"  – all 5 levels share this

    name             = Column(String(120), nullable=False)
    description      = Column(Text, nullable=True)
    icon_emoji       = Column(String(10),  nullable=True)

    # Classification
    category         = Column(SAEnum(AchievementCategory), nullable=False)
    difficulty       = Column(SAEnum(AchievementDifficulty), nullable=False)

    # Progression
    target           = Column(Integer, nullable=False)
    # null for Bronze (no prerequisite), filled for Silver-Diamond
    prerequisite_key = Column(String(100), nullable=True)

    # Misc
    unit             = Column(String(50), nullable=True)   # "visits", "days", …
    points           = Column(Integer, default=0)
    is_active        = Column(Boolean, default=True)
    created_at       = Column(DateTime(), server_default=func.now())

    client_achievements = relationship("ClientAchievement", back_populates="achievement")
