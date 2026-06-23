from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Numeric, Enum
from sqlalchemy.sql import func
import enum
from app.database import Base

class CoachMembershipStatus(str, enum.Enum):
    active    = "active"
    suspended = "suspended"

class GymCoachMembership(Base):
    __tablename__ = "gym_coach_memberships"

    id = Column(Integer, primary_key=True, index=True)
    gymID = Column("gymID", Integer, ForeignKey("gyms.gymID" ,ondelete="CASCADE"), nullable=False)
    coachID = Column("coachID", Integer, ForeignKey("coaches.coachID" ,ondelete="CASCADE"), nullable=False)
    hire_date = Column(DateTime(timezone=True), server_default=func.now())
    status = Column(Enum(CoachMembershipStatus), default=CoachMembershipStatus.active)