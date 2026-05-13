# app/models/gym_clients.py
from app.database import Base
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum

# Stores the relationship between a client and a gym. One client can potentially join multiple gyms.
class GymClientStatus(str, enum.Enum):
    active    = "active"
    suspended = "suspended"


class GymClient(Base):
    __tablename__ = "gym_clients"

    id        = Column(Integer, primary_key=True, index=True)
    gymID     = Column("gymID",    Integer, ForeignKey("gyms.gymID"),       nullable=False)
    clientID  = Column("clientID", Integer, ForeignKey("clients.clientID"), nullable=False)
    joined_at = Column(DateTime(timezone=True), server_default=func.now())
    status    = Column(Enum(GymClientStatus), default=GymClientStatus.active, nullable=False)

    gym    = relationship("Gym")
    client = relationship("Client")
    