from sqlalchemy import Column,Integer,String,Date,Time,ForeignKey
from app.database import Base


class ClassSession(Base):
    __tablename__= "class_sessions"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    date = Column(Date,nullable=False)
    start_time = Column(Time,nullable=False)

    # foreign keys
    # gym_id = Column(Integer,ForeignKey("gyms.id"),nulable=False)
    coach_id = Column(Integer, ForeignKey("coaches.coachID"), nullable=False)

    current_clients = Column(Integer,default=0)
    max_clients = Column(Integer, nullable=False)

