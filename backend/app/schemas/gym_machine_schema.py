"""
app/schemas/gym_machine_schema.py
──────────────────────────────────
Pydantic schemas for Gym and GymMachine endpoints.
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# ── Gym ───────────────────────────────────────────────────────────────────────

class GymCreate(BaseModel):
    name:      str            = Field(..., example="Titan Gym – Downtown")
    location:  Optional[str] = Field(None, example="123 Main St, Cairo")
    is_active: bool           = Field(True)


class GymResponse(BaseModel):
    gymID:      int
    name:       str
    location:   Optional[str]
    is_active:  bool
    created_at: Optional[datetime]

    class Config:
        from_attributes = True


# ── Machine ───────────────────────────────────────────────────────────────────

class MachineCreate(BaseModel):
    name:             str            = Field(..., example="Treadmill")
    category:         Optional[str] = Field(None, example="Cardio")
    description:      Optional[str] = Field(None, example="Commercial treadmill, max 20 km/h")
    muscle_groups:    Optional[str] = Field(None, example="quads,calves,glutes")
    is_valid:         bool           = Field(True)
    maintenance_note: Optional[str] = Field(None)


class MachineUpdate(BaseModel):
    name:             Optional[str]  = None
    category:         Optional[str]  = None
    description:      Optional[str]  = None
    muscle_groups:    Optional[str]  = None
    is_valid:         Optional[bool] = None
    maintenance_note: Optional[str]  = None


class MachineResponse(BaseModel):
    machineID:        int
    gymID:            int
    name:             str
    category:         Optional[str]
    description:      Optional[str]
    muscle_groups:    Optional[str]
    is_valid:         bool
    maintenance_note: Optional[str]
    created_at:       Optional[datetime]
    updated_at:       Optional[datetime]

    class Config:
        from_attributes = True


# ── Combined gym + machines (used by Gemini context) ─────────────────────────

class GymWithMachines(BaseModel):
    gymID:     int
    name:      str
    location:  Optional[str]
    machines:  List[MachineResponse]

    class Config:
        from_attributes = True