"""
app/models/client_achievement.py
──────────────────────────────────
Table:
  client_achievements – per-client progress & unlock status for each achievement level

One row is created per client per achievement level when that level becomes active.
"""

from sqlalchemy import (
    Column, Integer, Boolean,
    DateTime, ForeignKey, UniqueConstraint,
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class ClientAchievement(Base):
    __tablename__ = "client_achievements"

    __table_args__ = (
        UniqueConstraint("clientID", "achievementID", name="uq_client_achievement"),
    )

    id            = Column(Integer, primary_key=True, index=True)
    clientID      = Column(Integer, ForeignKey("clients.clientID"),           nullable=False)
    achievementID = Column(Integer, ForeignKey("achievements.achievementID"), nullable=False)

    # Progress
    current_value  = Column(Integer, default=0, nullable=False)
    best_value     = Column(Integer, default=0, nullable=False)  # highest value ever recorded
    current_streak = Column(Integer, default=0, nullable=False)  # used by STREAK category
    longest_streak = Column(Integer, default=0, nullable=False)

    # Unlock state
    is_unlocked = Column(Boolean, default=False, nullable=False)
    unlocked_at = Column(DateTime(timezone=True), nullable=True)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    achievement = relationship("Achievement", back_populates="client_achievements")
