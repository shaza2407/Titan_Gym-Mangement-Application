
from app.database import Base
from sqlalchemy import Column, Integer, ForeignKey

class Admin(Base):
    __tablename__ = "administrators"

    adminID = Column("adminID", Integer, primary_key=True, index=True)
    userID  = Column("userID", Integer, ForeignKey("users.userID"), nullable=False)

