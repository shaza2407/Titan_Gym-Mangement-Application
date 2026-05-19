
from app.database import Base
from sqlalchemy import Column, Date, Integer, String, ForeignKey, Text

# extends from user table
# Stores the client's profile data. Created once at signup. Never changes when they join/leave gyms.
class Client(Base):
    __tablename__ = "clients"

    clientID     = Column("clientID", Integer, primary_key=True , index=True)
    userID       = Column("userID", Integer, ForeignKey("users.userID"), nullable=False)  # ← matches
    fitness_goal = Column(String, nullable=True)
    date_of_birth     = Column(Date, nullable=True)   
    gender       = Column(String, nullable=True)

    # profile page needs
    bio                   = Column(Text,    nullable=True)
    emergency_contact     = Column(String,  nullable=True)  



