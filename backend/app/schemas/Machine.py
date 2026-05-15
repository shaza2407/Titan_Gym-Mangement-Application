from pydantic import BaseModel, Field
from typing import Optional, List

class MachineBase(BaseModel):
    machineName: str = Field(..., example="Treadmill X")
    machineType: str = Field(..., example="Cardio")
    muscleGroup: Optional[str] = Field(None, example="Legs")
    description: Optional[str] = Field(None, example="High-end commercial treadmill")

class MachineCreate(MachineBase):
    pass

class MachineUpdate(BaseModel):
    machineName: Optional[str] = None
    machineType: Optional[str] = None
    muscleGroup: Optional[str] = None
    description: Optional[str] = None

class MachineResponse(MachineBase):
    machineID: int

    class Config:
        from_attributes = True