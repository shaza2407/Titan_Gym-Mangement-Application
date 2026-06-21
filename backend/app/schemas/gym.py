from pydantic import BaseModel, Field
from typing import Optional, List


# Machine input (used when creating a gym)
class MachineInventoryInput(BaseModel):
    machineName: str        
    machineType: str       
    quantity: int = 1


# Machine output (used in GymResponse)
class MachineInventoryResponse(BaseModel):
    inventoryID: int
    machineName: str       
    machineType: str        
    quantity: int

    class Config:
        from_attributes = True


# Base
class GymBase(BaseModel):
    gymName: str = Field(..., example="FitZone")
    location: str = Field(..., example="123 Main St, Cairo")
    gymType: str = Field(..., example="mixed")
    openingHours: str = Field(..., example="06:00")
    closingHours: str = Field(..., example="23:00")


# Create
class GymCreate(GymBase):
    machines: List[MachineInventoryInput] = []


# Update
class GymUpdate(BaseModel):
    gymName: Optional[str] = None
    location: Optional[str] = None
    gymType: Optional[str] = None
    openingHours: Optional[str] = None
    closingHours: Optional[str] = None


# Response
class GymResponse(GymBase):
    gymID: int
    adminID: int
    QRCode: Optional[str] = None

    class Config:
        from_attributes = True


class GymDashboardStats(BaseModel):
    gymID: int
    gymName: str
    totalMembers: int
    activeSubscriptions: int
    todayAttendance: int
    totalClasses: int = 0

    class Config:
        from_attributes = True