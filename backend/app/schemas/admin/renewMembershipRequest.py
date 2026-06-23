from pydantic import BaseModel

class RenewMembershipRequest(BaseModel):
    subscription_type: str = "monthly"  # "monthly" | "yearly"
    duration_count: int = 1
    price: float