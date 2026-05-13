from app.database import Base
from sqlalchemy import Column, Integer, ForeignKey , String 
from sqlalchemy.orm import relationship

class GymMachineInventory(Base):
    __tablename__ = "gym_machine_inventory"

    inventoryID = Column("inventoryID", Integer,primary_key=True, index=True)
    gymID = Column("gymID", Integer,  ForeignKey("gyms.gymID"), nullable=False)
    machineID = Column("machineID", Integer, ForeignKey("machines.machineID"), nullable=False)
    quantity = Column("quantity", Integer, nullable=False, default=1)
    status = Column("status", String, nullable=False, default="available")  # available, maintenance, out_of_service

    gym = relationship("Gym",back_populates="machine_inventory")
    machine = relationship("Machine", back_populates="gym_inventories")
 
 