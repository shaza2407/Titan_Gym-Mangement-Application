from pydantic import BaseModel, EmailStr, Field, field_validator
from app.schemas.shared.UserRole import UserRole

class SignUpRequest(BaseModel):
    name: str
    email: EmailStr
    phone: str
    password: str = Field()
    role: UserRole


    @field_validator('password')
    @classmethod
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be 8 characters or more')
        return v
    
    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v):
        if not v.startswith('01') or len(v) != 11 or not v.isdigit():
            raise ValueError('Phone must be 11 digits and start with 01')
        return v