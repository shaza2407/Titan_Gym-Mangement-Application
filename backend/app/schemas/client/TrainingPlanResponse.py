# app/schemas/TraingPlanResponse.py
from pydantic import BaseModel
from typing import Optional, List, Any
from datetime import datetime
from app.models.training_plan import PlanStatus


class DayPlan(BaseModel):
    day:       str
    focus:     str
    exercises: List[Any]
    notes:     Optional[str] = None
    isCompleted: bool = False


class WeekPlan(BaseModel):
    week:  int
    theme: Optional[str] = None
    days:  List[DayPlan]


class TrainingPlanResponse(BaseModel):
    planID:         int
    clientID:       int
    title:          str
    goal:           str
    level:          Optional[str]
    weeks:          Optional[int]
    status:         Optional[PlanStatus] = PlanStatus.IN_PROGRESS
    completed_at:   Optional[datetime]   = None
    version:        int = 1
    parent_plan_id: Optional[int]        = None
    plan:           List[WeekPlan]
    raw_json:       str
    created_at:     Optional[datetime] = None

    model_config = {"from_attributes": True}


class TrainingPlanSummary(BaseModel):
    """Lightweight version for plan listings."""
    planID:         int
    title:          str
    goal:           str
    level:          Optional[str]
    weeks:          Optional[int]
    status:         Optional[PlanStatus] = PlanStatus.IN_PROGRESS
    completed_at:   Optional[datetime]   = None
    version:        int = 1
    parent_plan_id: Optional[int]        = None
    is_active:      bool = True
    created_at:     Optional[datetime] = None

    model_config = {"from_attributes": True}