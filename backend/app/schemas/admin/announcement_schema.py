# announcement_schema.py
from pydantic import BaseModel, Field , ConfigDict
from datetime import datetime
from typing import Literal

class CreateAnnouncementRequest(BaseModel):
    title: str = Field(..., max_length=255)
    content: str = Field(..., max_length=1000)
    reciever: Literal[
        'Clients only',
        'Coaches only',
        'Clients and Coaches',
    ] = 'Clients and Coaches'  

class AnnouncementResponse(BaseModel):
    announce_id: int
    gymID: int
    title: str
    content: str
    reciever: str           
    created_at: datetime

    class Config:
        model_config = ConfigDict(from_attributes=True)