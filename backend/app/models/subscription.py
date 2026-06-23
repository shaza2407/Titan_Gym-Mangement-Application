# models/Announcement.py
from sqlalchemy import Column, Integer, ForeignKey, DateTime, String
from sqlalchemy.sql import func
from app.database import Base

class Subscription(Base):
    __tablename__ = "subscriptions"

    subscriptionID = Column(Integer, primary_key=True, index=True)
    clientID = Column(Integer, ForeignKey("clients.clientID" ,  ondelete="CASCADE"), nullable=False)
    gymID = Column(Integer, ForeignKey("gyms.gymID", ondelete="CASCADE") ,nullable=False)
    supscriptionPrice    = Column(Integer, nullable=False)
    duration_count     = Column(Integer, nullable=False)   #number of months or years
    billingDate    = Column(DateTime(timezone= False),server_default=func.now(), nullable=False)  
