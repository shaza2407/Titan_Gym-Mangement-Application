from pydantic import BaseModel , field_validator
from typing import Optional
from datetime import date as DateType
from datetime import datetime

class ClientProfileUpdate(BaseModel):
    name:              Optional[str]      = None
    phone:             Optional[str]      = None
    gender:            Optional[str]      = None
    fitness_goal:      Optional[str]      = None
    date_of_birth:     Optional[DateType] = None
    bio:               Optional[str]      = None
    emergency_contact: Optional[str]      = None

    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v):
        if not v.startswith('01') or len(v) != 11 or not v.isdigit():
            raise ValueError('Phone must be 11 digits and start with 01')
        return v

class ClientProfileResponse(BaseModel):
    userID:            int
    name:              str
    email:             str
    phone:             Optional[str]      = None
    clientID:          int
    gender:            Optional[str]      = None
    fitness_goal:      Optional[str]      = None
    date_of_birth:     Optional[DateType] = None
    age:               Optional[int]      = None  # calculated
    bio:               Optional[str]      = None
    emergency_contact: Optional[str]      = None

    class Config:
        from_attributes = True