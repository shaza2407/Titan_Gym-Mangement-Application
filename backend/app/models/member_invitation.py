from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Enum , Date
from sqlalchemy.sql import func
import enum

from app.database import Base

class InvitationStatus(str, enum.Enum):
    pending  = "pending"
    accepted = "accepted"
    rejected = "rejected"

class MemberInvitation(Base):
    __tablename__ = "member_invitations"

    id = Column(Integer, primary_key=True, index=True)
    gymID = Column("gymID", Integer, ForeignKey("gyms.gymID"), nullable=False)
    email = Column(String, nullable=False)
    token = Column(String, nullable=False, unique=True)
    status = Column(Enum(InvitationStatus), default=InvitationStatus.pending)
    sent_at = Column(DateTime(timezone=True), server_default=func.now())
    invited_as = Column(String, nullable=False, default="client")  # "client" | "coach"
    expires_at = Column(DateTime(timezone=True), nullable=True)
    subscription = Column(String, nullable=True)        # "1 month" | "1 year" months or years
    subscription_end = Column(Date, nullable=True)