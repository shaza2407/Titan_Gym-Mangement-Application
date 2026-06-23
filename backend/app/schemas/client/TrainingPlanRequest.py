from pydantic import BaseModel, Field
from typing import Optional, List, Any
from datetime import datetime


# ─── Request ──────────────────────────────────────────────────────────────────

class TrainingPlanRequest(BaseModel):
    """
    Body sent by the client (or the frontend on behalf of the client)
    when asking the AI agent to generate a training plan.
    """
    fitness_goal: str = Field(
        ...,
        example="weight loss",
        description="Primary fitness goal: weight loss, muscle gain, endurance, flexibility, etc."
    )
    age: Optional[int]    = Field(None,  example=28)
    gender: Optional[str] = Field(None,  example="male")
    level: Optional[str]  = Field("beginner", example="beginner",
                                   description="beginner | intermediate | advanced")
    weeks: Optional[int]  = Field(8, example=8,
                                   description="Desired plan duration in weeks (4–16)")
    injuries: Optional[str] = Field(None, example="knee pain",
                                     description="Any injuries or limitations the plan should respect")
    days_per_week: Optional[int] = Field(4, example=4,
                                          description="How many training days per week")
    equipment: Optional[str] = Field("full gym", example="full gym",
                                      description="Available equipment: full gym, home, bodyweight, dumbbells only, etc.")

