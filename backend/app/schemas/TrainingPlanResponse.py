# app/schemas/TrainingPlanResponse.py
from pydantic import BaseModel
from typing import Optional, List, Any
from datetime import datetime
from app.models.training_plan import PlanStatus


class DayPlan(BaseModel):
    day:       str
    focus:     str
    exercises: List[Any]
    notes:     Optional[str] = None


class WeekPlan(BaseModel):
    week:  int
    theme: Optional[str] = None
    days:  List[DayPlan]


class TrainingPlanResponse(BaseModel):
    planID:       int
    clientID:     int
    title:        str
    goal:         str
    level:        Optional[str]
    weeks:        Optional[int]
    # BUG FIX: status and completed_at were missing — frontend could never
    # show plan status and the /complete endpoint had no response shape.
    status:       Optional[PlanStatus] = PlanStatus.IN_PROGRESS
    completed_at: Optional[datetime]   = None
    plan:         List[WeekPlan]
    raw_json:     str
    created_at:   datetime

    model_config = {"from_attributes": True}


class TrainingPlanSummary(BaseModel):
    """Lightweight version for listing all plans of a client."""
    planID:       int
    title:        str
    goal:         str
    level:        Optional[str]
    weeks:        Optional[int]
    # BUG FIX: status was missing from summary too
    status:       Optional[PlanStatus] = PlanStatus.IN_PROGRESS
    completed_at: Optional[datetime]   = None
    created_at:   datetime

    model_config = {"from_attributes": True}
