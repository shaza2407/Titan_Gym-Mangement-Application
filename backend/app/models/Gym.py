from app.database import Base
from sqlalchemy import Column, Integer, ForeignKey , Double , String 
from sqlalchemy.orm import relationship
from datetime import datetime
class Gym(Base):
    __tablename__ = "gyms"
    gymID = Column("gymID", Integer, primary_key=True , index=True)
    gymName = Column("gymName", String , nullable=False)
    adminID = Column("adminID", Integer, ForeignKey("administrators.adminID"), nullable=False)
    subscriptionPrice = Column("subscriptionPrice", Double , nullable=False)
    yearlySubscriptionPrice = Column("yearlySubscriptionPrice", Double , nullable=True)
    location = Column("location", String , nullable=False)
    QRCode = Column("QRCode", String , nullable=True)
    gymType = Column("GYMTYPE", String , nullable=False)        #males , females, mixed
    openingHours = Column("openingHours", String , nullable=False)
    closingHours = Column("closingHours", String , nullable=False)

    machine_inventory = relationship("GymMachineInventory", back_populates="gym", cascade="all, delete-orphan")
    memberships = relationship("GymClientMembership", backref="gym") 