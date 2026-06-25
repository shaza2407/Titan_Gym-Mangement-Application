"""
app/models/training_plan.py
────────────────────────────
Tables:
  training_plans              – one row per plan version
  training_plan_tracking      – daily workout completion log
  training_plan_week_progress – aggregated per-week stats

Versioning rules
  • Every edit creates a NEW row (never overwrite plan_json).
  • parent_plan_id links the new version back to the original.
  • version increments from the parent.
  • is_active = True means the client sees this version; all older versions
    for the same chain are set to False.
"""

import enum
from sqlalchemy import (
    Column, Integer, String, Text, Boolean, Float,
    DateTime, Date, ForeignKey, Enum as SAEnum, JSON
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


# ── Enums ─────────────────────────────────────────────────────────────────────

class PlanStatus(str, enum.Enum):
    IN_PROGRESS = "in_progress"
    COMPLETED   = "completed"
    PAUSED      = "paused"
    ABANDONED   = "abandoned"


class WorkoutStatus(str, enum.Enum):
    COMPLETED = "completed"
    PARTIAL   = "partial"
    SKIPPED   = "skipped"
    PLANNED   = "planned"


class DayStatus(str, enum.Enum):
    COMPLETED   = "completed"
    IN_PROGRESS = "in_progress"
    PLANNED     = "planned"


# ── Training plan (versioned) ─────────────────────────────────────────────────

class TrainingPlan(Base):
    """
    Each row is an immutable snapshot of a plan.
    Edits create a new row; old rows are preserved (is_active = False).
    """
    __tablename__ = "training_plans"

    planID         = Column("planID",   Integer, primary_key=True, index=True)
    clientID       = Column("clientID", Integer, ForeignKey("clients.clientID" ,  ondelete="CASCADE"), nullable=False)

    # Versioning
    parent_plan_id = Column(Integer, ForeignKey("training_plans.planID"), nullable=True)
    version        = Column(Integer, default=1, nullable=False)
    is_active      = Column(Boolean, default=True, nullable=False)

    # Plan metadata
    title          = Column(String(200), nullable=False)
    goal           = Column(String(100), nullable=False)
    level          = Column(String(50),  nullable=True)
    weeks          = Column(Integer,     nullable=True)
    gym_id         = Column(Integer, ForeignKey("gyms.gymID" ,  ondelete="CASCADE"), nullable=True)

    # Full AI-generated plan stored as JSON text
    plan_json      = Column(Text, nullable=False)

    # Status tracking
    status         = Column(SAEnum(PlanStatus), default=PlanStatus.IN_PROGRESS, nullable=False)
    completed_at   = Column(DateTime(timezone=True), nullable=True)

    # Timestamps
    created_at     = Column(DateTime(timezone=True), server_default=func.now())
    updated_at     = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    tracking       = relationship("TrainingPlanTracking", back_populates="plan",
                                  cascade="all, delete-orphan")
    week_progress  = relationship("TrainingPlanWeekProgress", back_populates="plan",
                                  cascade="all, delete-orphan")
    parent = relationship(
        "TrainingPlan",
        remote_side=[planID],
        back_populates="versions"
    )

    versions = relationship(
        "TrainingPlan",
        back_populates="parent"
    )


# ── Daily workout tracking ─────────────────────────────────────────────────────

class TrainingPlanTracking(Base):
    """One row per day a client logs workout progress."""
    __tablename__ = "training_plan_tracking"

    trackingID            = Column("trackingID", Integer, primary_key=True, index=True)
    clientID              = Column("clientID", Integer, ForeignKey("clients.clientID" , ondelete="CASCADE"), nullable=False)
    planID                = Column("planID",   Integer, ForeignKey("training_plans.planID",  ondelete="CASCADE"), nullable=False)

    tracking_date         = Column(Date, nullable=False)
    week_number           = Column(Integer, nullable=True)
    day_number            = Column(Integer, nullable=True)

    # Exercise completion
    planned_exercises     = Column(Integer, default=0)
    completed_exercises   = Column(Integer, default=0)
    completion_percentage = Column(Float,   default=0.0)
    completed_exercises_list = Column(JSON, nullable=True)

    status                = Column(SAEnum(WorkoutStatus), default=WorkoutStatus.PLANNED)
    duration_minutes      = Column(Integer, nullable=True)
    notes                 = Column(Text,    nullable=True)
    completed_at          = Column(DateTime(timezone=True), nullable=True)

    plan = relationship("TrainingPlan", back_populates="tracking")


# ── Weekly aggregate ──────────────────────────────────────────────────────────

class TrainingPlanWeekProgress(Base):
    """Aggregated completion stats per week per plan."""
    __tablename__ = "training_plan_week_progress"

    id               = Column(Integer, primary_key=True, index=True)
    clientID         = Column("clientID", Integer, ForeignKey("clients.clientID" ,  ondelete="CASCADE"), nullable=False)
    planID           = Column("planID",   Integer, ForeignKey("training_plans.planID" ,  ondelete="CASCADE"), nullable=False)

    week_number      = Column(Integer, nullable=False)
    week_start_date  = Column(Date, nullable=True)
    week_end_date    = Column(Date, nullable=True)

    total_days       = Column(Integer, default=0)
    completed_days   = Column(Integer, default=0)
    skipped_days     = Column(Integer, default=0)
    average_completion = Column(Float, default=0.0)
    week_status      = Column(SAEnum(DayStatus), default=DayStatus.PLANNED)

    plan = relationship("TrainingPlan", back_populates="week_progress")