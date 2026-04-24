
from app.models import User
from sqlalchemy import Column, Integer, ForeignKey

class Coach(User):
    __tablename__ = "coaches"

    coachID = Column("coachID", Integer, primary_key=True)
    userID  = Column("userID", Integer, ForeignKey("users.userID"), nullable=False)

    __mapper_args__ = {"polymorphic_identity": "coach"}