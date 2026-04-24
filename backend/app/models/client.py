
from app.database import Base
from sqlalchemy import Column, Integer, String, ForeignKey

# extends from user table
class Client(Base):
    __tablename__ = "clients"

    clientID     = Column("clientID", Integer, primary_key=True , index=True)
    userID       = Column("userID", Integer, ForeignKey("users.userID"), nullable=False)  # ← matches
    fitness_goal = Column(String, nullable=True)
    age          = Column(Integer, nullable=True)
    gender       = Column(String, nullable=True)

