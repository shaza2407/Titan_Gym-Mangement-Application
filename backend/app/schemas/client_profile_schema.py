from pydantic import BaseModel
from typing import Optional

class ClientProfileUpdate(BaseModel):
    # From User table
    name:              Optional[str] = None
    phone:             Optional[str] = None

    # From Client table
    age:               Optional[int] = None
    gender:            Optional[str] = None
    fitness_goal:      Optional[str] = None
    bio:               Optional[str] = None
    emergency_contact: Optional[str] = None
    profile_picture:   Optional[str] = None

class ClientProfileResponse(BaseModel):
    # From User table
    userID:            int
    name:              str
    email:             str
    phone:             Optional[str] = None

    # From Client table
    clientID:          int
    age:               Optional[int] = None
    gender:            Optional[str] = None
    fitness_goal:      Optional[str] = None
    bio:               Optional[str] = None
    emergency_contact: Optional[str] = None
    profile_picture:   Optional[str] = None

    class Config:
        from_attributes = True