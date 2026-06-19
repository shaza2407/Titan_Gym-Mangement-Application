from pydantic import BaseModel, Field
from datetime import datetime

class CreateAnnouncementRequest(BaseModel):
    title: str = Field(..., max_length=255)
    content: str = Field(..., max_length=1000)

class AnnouncementResponse(BaseModel):
    announce_id: int
    gymID: int
    title: str
    content: str
    created_at: datetime

    class Config:
        from_attributes = True