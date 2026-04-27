
from pydantic import BaseModel, EmailStr

from app.schemas.UserRole import UserRole
class SignUpRequest(BaseModel):
    name: str
    email: EmailStr
    phone: str
    password: str
    role: UserRole
    fitness_goal: str 
    age: int 
    gender: str 