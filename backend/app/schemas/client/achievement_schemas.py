# app/schemas/achievement_schemas.py
from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class AchievementProgressResponse(BaseModel):
    """
    Returned by GET /achievements/
    One item per badge — matches exactly what the My Achievements screen shows.
    """
    achievementID : int
    key           : str
    name          : str
    description   : str
    icon_emoji    : Optional[str]
    target        : int
    unit          : str
    current_value : int
    percent       : int          # 0-100, rounded
    is_unlocked   : bool
    unlocked_at   : Optional[datetime]

    model_config = {"from_attributes": True}

