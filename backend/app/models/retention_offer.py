from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Date, Enum, Text
from sqlalchemy.sql import func
import enum
from app.database import Base

class OfferType(str, enum.Enum):
    discount = "discount"
    supplements = "supplements"
    free_sessions = "free_sessions"
    membership_upgrade = "membership_upgrade"

class TargetType(str, enum.Enum):
    highest_risk = "highest_risk"
    lowest_risk = "lowest_risk"
    all_members = "all_members"
    manual_selection = "manual_selection"

class RetentionOffer(Base):
    __tablename__ = "retention_offers"

    id = Column(Integer, primary_key=True, index=True)
    gymId = Column(Integer, ForeignKey("gyms.gymID"), nullable=False)
    title = Column(String, nullable=False)
    offer_type = Column(Enum(OfferType), nullable=False)
    description = Column(Text, nullable=True)
    benefit = Column(String, nullable=False) ### I think I should change this
    valid_until = Column(Date, nullable=True)
    target_type = Column(Enum(TargetType), nullable=False)
    number_of_members = Column(Integer, default=0)   # number of members offer was sent to
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class RetentionOfferRecipient(Base):
    __tablename__ = "retention_offer_recipients"

    id = Column(Integer, primary_key=True, index=True)
    offer_id = Column(Integer, ForeignKey("retention_offers.id"), nullable=False)
    membership_id = Column(Integer, ForeignKey("gym_client_memberships.id"), nullable=False)
    risk_level = Column(String, nullable=True)  # snapshot at send time: "High Risk", "Mid Risk", "Low Risk"
