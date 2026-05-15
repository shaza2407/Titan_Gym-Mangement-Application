"""
app/schemas/achievement_schema.py
──────────────────────────────────
Pydantic schemas for achievements, badges, and check-ins.
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date
from app.models.achievement import AchievementType


# ── Admin: create/update badge definitions ────────────────────────────────────

class AchievementCreate(BaseModel):
    title:            str             = Field(..., example="3 Day Warrior")
    description:      Optional[str]  = Field(None, example="Check in 3 days in a row")
    icon_url:         Optional[str]  = Field(None)
    achievement_type: AchievementType = Field(..., example="STREAK")
    target_value:     int             = Field(..., example=3)
    reward_points:    int             = Field(0,   example=50)
    is_active:        bool            = Field(True)


class AchievementResponse(BaseModel):
    achievement_id:   int
    title:            str
    description:      Optional[str]
    icon_url:         Optional[str]
    achievement_type: AchievementType
    target_value:     int
    reward_points:    int
    is_active:        bool
    created_at:       Optional[datetime]

    class Config:
        from_attributes = True


# ── User: earned badge ────────────────────────────────────────────────────────

class EarnedBadge(BaseModel):
    achievement_id: int
    title:          str
    description:    Optional[str]
    icon_url:       Optional[str]
    reward_points:  int
    earned_at:      Optional[datetime]

    class Config:
        from_attributes = True


# ── User: in-progress badge ───────────────────────────────────────────────────

class InProgressBadge(BaseModel):
    achievement_id: int
    title:          str
    description:    Optional[str]
    icon_url:       Optional[str]
    progress:       int
    target:         int
    percentage:     float
    remaining:      int

    class Config:
        from_attributes = True


# ── Dashboard stats ───────────────────────────────────────────────────────────

class AchievementDashboard(BaseModel):
    total:                 int
    earned:                int
    in_progress:           int
    completion_percentage: float
    current_streak:        int


# ── Check-in ──────────────────────────────────────────────────────────────────

class CheckinRequest(BaseModel):
    gymID: Optional[int] = Field(None, example=1, description="ID of the gym being visited")


class CheckinResponse(BaseModel):
    success:    bool
    message:    str
    checkin_id: int
    new_badges: List[EarnedBadge] = []