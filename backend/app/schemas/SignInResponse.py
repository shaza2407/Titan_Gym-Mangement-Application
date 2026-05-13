
from pydantic import BaseModel
from app.schemas.UserRole import UserRole
from typing import Optional

class SignInResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"       # JWT token
    role: UserRole
    userID: int

    # fields Flutter needs for routing 
    is_gym_connected: bool          = False
    gymID:            Optional[int] = None
    gymName:          Optional[str] = None
    clientID:         Optional[int] = None