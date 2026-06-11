from pydantic import BaseModel
from typing import Optional


class AdminProfileUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
