
from pydantic import BaseModel
from app.schemas.shared.UserRole import UserRole
from typing import Optional

class SignInResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"       # JWT token
    role: UserRole
    userID: int
