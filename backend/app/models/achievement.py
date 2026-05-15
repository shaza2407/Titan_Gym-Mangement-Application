"""
app/models/achievement.py
──────────────────────────
Tables:
  achievements        – badge definitions (admin-managed)
  user_achievements   – per-user progress & earned status
  user_checkins       – gym check-in log
"""

import enum
from sqlalchemy import (
    Column, Integer, String, Boolean, Text,
    DateTime, Date, ForeignKey, Enum as SAEnum, UniqueConstraint
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


# ── Enum ──────────────────────────────────────────────────────────────────────

class AchievementType(str, enum.Enum):
    CHECKIN       = "CHECKIN"        # total check-ins
    STREAK        = "STREAK"         # consecutive-day streak
    WEEKLY        = "WEEKLY"         # check-ins within one calendar week
    CLASS         = "CLASS"          # group classes attended
    TRAINING_PLAN = "TRAINING_PLAN"  # training plans completed
    EARLY_BIRD    = "EARLY_BIRD"     # check-ins before 07:00
    MONTHLY       = "MONTHLY"        # check-ins within one calendar month


# ── Badge definitions ─────────────────────────────────────────────────────────

class Achievement(Base):
    __tablename__ = "achievements"

    achievement_id   = Column(Integer, primary_key=True, index=True)
    title            = Column(String(100), nullable=False)
    description      = Column(Text,        nullable=True)
    icon_url         = Column(String(500), nullable=True)
    achievement_type = Column(SAEnum(AchievementType), nullable=False)
    target_value     = Column(Integer,     nullable=False)   # e.g. 1, 3, 10, 20
    reward_points    = Column(Integer,     default=0)
    is_active        = Column(Boolean,     default=True, nullable=False)
    created_at       = Column(DateTime(timezone=True), server_default=func.now())

    user_achievements = relationship("UserAchievement", back_populates="achievement")


# ── Per-user progress ─────────────────────────────────────────────────────────

class UserAchievement(Base):
    __tablename__ = "user_achievements"

    __table_args__ = (
        UniqueConstraint("userID", "achievement_id", name="uq_user_achievement"),
    )

    id             = Column(Integer, primary_key=True, index=True)
    userID         = Column(Integer, ForeignKey("users.userID"), nullable=False)
    achievement_id = Column(Integer, ForeignKey("achievements.achievement_id"), nullable=False)
    progress_value = Column(Integer, default=0, nullable=False)
    is_completed   = Column(Boolean, default=False, nullable=False)
    completed_at   = Column(DateTime(timezone=True), nullable=True)
    created_at     = Column(DateTime(timezone=True), server_default=func.now())
    updated_at     = Column(DateTime(timezone=True), onupdate=func.now())

    achievement = relationship("Achievement", back_populates="user_achievements")


# ── Check-in log ──────────────────────────────────────────────────────────────

class UserCheckin(Base):
    __tablename__ = "user_checkins"

    __table_args__ = (
        UniqueConstraint("userID", "checkin_date", name="uq_user_checkin_day"),
    )

    id           = Column(Integer, primary_key=True, index=True)
    userID       = Column(Integer, ForeignKey("users.userID"), nullable=False)
    gymID        = Column(Integer, ForeignKey("gyms.gymID"),   nullable=True)   # which gym
    checkin_date = Column(Date,    nullable=False)
    checkin_time = Column(DateTime(timezone=True), server_default=func.now())   # for Early Bird logic
    created_at   = Column(DateTime(timezone=True), server_default=func.now())