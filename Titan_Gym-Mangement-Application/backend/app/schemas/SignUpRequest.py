
from pydantic import BaseModel, EmailStr , Field

from app.schemas.UserRole import UserRole
class SignUpRequest(BaseModel):
    name: str
    email: EmailStr
    phone: str
    password: str = Field(min_length=8)
    role: UserRole
