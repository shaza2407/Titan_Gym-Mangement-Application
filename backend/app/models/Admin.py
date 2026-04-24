
from app.models import User
from sqlalchemy import Column, Integer, ForeignKey

class Admin(User):
    __tablename__ = "administrators"

    adminID = Column("adminID", Integer, primary_key=True)
    userID  = Column("userID", Integer, ForeignKey("users.userID"), nullable=False)

    __mapper_args__ = {"polymorphic_identity": "admin"}