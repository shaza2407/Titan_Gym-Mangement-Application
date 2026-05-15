from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.database import Base


class TrainingPlan(Base):
    """
    Stores AI-generated training plans for gym clients.
    Each plan is linked to a client and contains the full
    plan JSON returned by the Gemini agent.
    """
    __tablename__ = "training_plans"

    planID      = Column("planID",    Integer, primary_key=True, index=True)
    clientID    = Column("clientID",  Integer, ForeignKey("clients.clientID"), nullable=False)
    title       = Column(String,      nullable=False)           # e.g. "8-Week Weight Loss Plan"
    goal        = Column(String,      nullable=False)           # fitness goal used at generation time
    level       = Column(String,      nullable=True)            # beginner / intermediate / advanced
    weeks       = Column(Integer,     nullable=True)            # plan duration in weeks
    plan_json   = Column(Text,        nullable=False)           # full JSON from Gemini stored as text
    created_at  = Column(DateTime(timezone=True), server_default=func.now())
    updated_at  = Column(DateTime(timezone=True), onupdate=func.now())
