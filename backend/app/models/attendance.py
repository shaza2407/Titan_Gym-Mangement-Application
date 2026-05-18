"""
app/models/attendance.py
────────────────────────
Table:
  attendance – one row per gym visit

Multiple check-ins on the same calendar day are allowed (e.g. different gyms),
but streak / perfect-week logic de-duplicates by check_in_date.

check_in_hour, check_in_date, and day_of_week are pre-computed at insert time
so achievement queries never need to call date functions on every row.
"""

from sqlalchemy import Column, Integer, String, DateTime, Date, ForeignKey
from sqlalchemy.sql import func
from app.database import Base


class Attendance(Base):
    __tablename__ = "attendance"

    id            = Column(Integer, primary_key=True, index=True)
    membershipID  = Column(Integer, ForeignKey("gym_client_memberships.id"), nullable=True)
    clientID      = Column(Integer, ForeignKey("clients.clientID"), nullable=True)
    gymID         = Column(Integer, ForeignKey("gyms.gymID"), nullable=True)

    checked_in    = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Pre-indexed fields — populated by the attendance router before insert
    check_in_hour = Column(Integer,    nullable=True)   # 0–23  (gym local time)
    check_in_date = Column(Date,       nullable=True)   # calendar date (gym local tz)
    day_of_week   = Column(String(10), nullable=True)   # "monday" … "sunday"
