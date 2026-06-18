from pydantic import BaseModel
from datetime import date
from typing import Optional

class CompleteDayRequest(BaseModel):
    tracking_date: date
    completed_exercises: int
    total_exercises: int
    duration_minutes: Optional[int] = None