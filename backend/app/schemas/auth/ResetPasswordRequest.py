from pydantic import BaseModel, Field

class ResetPasswordRequest(BaseModel):
    email: str
    code: str        
    new_password: str