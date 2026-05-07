from app.database import Base
from sqlalchemy import Column, Integer, ForeignKey

class Coach(Base):
    __tablename__ = "coaches"

    coachID = Column("coachID", Integer, primary_key=True , index=True)
    userID  = Column("userID", Integer, ForeignKey("users.userID"), nullable=False)


