from app.database import Base
from sqlalchemy import Column, Integer, ForeignKey , String 
from sqlalchemy.orm import relationship

class GymMachineInventory(Base):
    __tablename__ = "gym_machine_inventory"

    inventoryID = Column("inventoryID", Integer, primary_key=True, index=True)
    gymID       = Column("gymID", Integer, ForeignKey("gyms.gymID" ,ondelete="CASCADE"), nullable=False)
    machineName = Column("machineName", String, nullable=False)   
    machineType = Column("machineType", String, nullable=False)   
    quantity    = Column("quantity", Integer, nullable=False, default=1)

    gym = relationship("Gym", back_populates="machine_inventory")