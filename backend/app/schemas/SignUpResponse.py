from pydantic import BaseModel
from app.schemas.UserRole import UserRole

class SignUpResponse(BaseModel):
    userID: int
    email: str
    phone: str
    name: str
    role: UserRole