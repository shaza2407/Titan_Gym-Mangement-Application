from pydantic import BaseModel

class ResendVerificationRequest(BaseModel):
    email: str