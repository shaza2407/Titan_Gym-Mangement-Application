from pydantic import BaseModel
from typing import Optional, List

class CompleteDayRequest(BaseModel):
    week_number: int
    day_number: int
    completed_exercises: int
    total_exercises: int
    duration_minutes: Optional[int] = None
    completed_exercise_indices: List[int] = []