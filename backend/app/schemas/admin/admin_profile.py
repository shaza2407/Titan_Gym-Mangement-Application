from pydantic import BaseModel ,field_validator
from typing import Optional


class AdminProfileUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None

    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v):
        if not v.startswith('01') or len(v) != 11 or not v.isdigit():
            raise ValueError('Phone must be 11 digits and start with 01')
        return v