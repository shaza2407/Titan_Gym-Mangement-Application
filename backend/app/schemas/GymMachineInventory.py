from pydantic import BaseModel, Field
from typing import Optional, List

from backend.app.schemas.Machine import MachineResponse


class InventoryBase(BaseModel):
    machineID: int
    quantity: int = Field(default=1)
    status: str = Field(default="available", example="available")

class InventoryCreate(InventoryBase):
    pass

class InventoryResponse(InventoryBase):
    inventoryID: int
    # This allows nesting the machine details inside the inventory list
    machine: Optional[MachineResponse] = None

    class Config:
        from_attributes = True