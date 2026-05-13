from pydantic import BaseModel, Field
from typing import Optional, List, Any
from datetime import datetime


# ─── Response ─────────────────────────────────────────────────────────────────

class DayPlan(BaseModel):
    day: str                  # e.g. "Monday" or "Day 1"
    focus: str                # e.g. "Upper Body – Push"
    exercises: List[Any]      # list of exercise dicts {name, sets, reps, rest}
    notes: Optional[str] = None


class WeekPlan(BaseModel):
    week: int
    theme: Optional[str] = None   # e.g. "Foundation Phase"
    days: List[DayPlan]


class TrainingPlanResponse(BaseModel):
    planID:     int
    clientID:   int
    title:      str
    goal:       str
    level:      Optional[str]
    weeks:      Optional[int]
    plan:       List[WeekPlan]          # parsed structure for the frontend
    raw_json:   str                     # full Gemini output (stored in DB)
    created_at: datetime

    class Config:
        from_attributes = True


class TrainingPlanSummary(BaseModel):
    """Lightweight version for listing all plans of a client."""
    planID:     int
    title:      str
    goal:       str
    level:      Optional[str]
    weeks:      Optional[int]
    created_at: datetime

    class Config:
        from_attributes = True
