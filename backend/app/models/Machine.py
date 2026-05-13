from app.database import Base
from sqlalchemy import Column, Integer, ForeignKey , Double , String
from sqlalchemy.orm import relationship

class Machine(Base):
    __tablename__ = "machines"
 
    machineID   = Column("machineID",   Integer, primary_key=True, index=True)
    machineName = Column("machineName", String,  nullable=False)   
    machineType = Column("machineType", String,  nullable=False)   
    muscleGroup = Column("muscleGroup", String,  nullable=True)    
    description = Column("description", String,  nullable=True)
 
    gym_inventories = relationship("GymMachineInventory", back_populates="machine")
 