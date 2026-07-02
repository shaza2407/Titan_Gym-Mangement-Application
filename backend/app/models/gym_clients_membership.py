from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Date, Enum
from sqlalchemy.sql import func
import enum
from app.database import Base

class ClientMembershipStatus(str, enum.Enum):
    active    = "active"
    suspended = "suspended"

class GymClientMembership(Base):
    __tablename__ = "gym_client_memberships"

    id = Column(Integer, primary_key=True, index=True)
    gymID = Column("gymID", Integer, ForeignKey("gyms.gymID" ,ondelete="CASCADE"), nullable=False)
    clientID = Column("clientID", Integer, ForeignKey("clients.clientID" ,ondelete="CASCADE"), nullable=False)
    subscription = Column(String, nullable=False)   # "Monthly" | "Annual"
    subscription_end = Column(Date, nullable=False)     # for "Expired" filter
    status = Column(Enum(ClientMembershipStatus), default=ClientMembershipStatus.active)
    joined_at = Column(DateTime(), server_default=func.now())