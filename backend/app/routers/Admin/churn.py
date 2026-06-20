import httpx
import numpy as np
from datetime import datetime, timezone, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.attendance import Attendance
from app.models.gym_clients_membership import GymClientMembership

ML_API_URL = "http://127.0.0.1:8000/predict"


def encode_days(days: int) -> int:
    if days <= 1:
        return 0   # low  : 0-1 days
    elif days <= 4:
        return 1   # mid  : 2-4 days
    else:
        return 2   # high : 5-7 days

def get_weekly_attendance(membership_id: int, db: Session) -> list:
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    since_90 = now - timedelta(days=90)
    records = db.query(Attendance.checked_in).filter(
        Attendance.membershipID == membership_id,
        Attendance.checked_in >= since_90
    ).all()

    checkins = [r.checked_in for r in records]
    weeks = []
    for i in range(11, -1, -1): ##
        week_start = now - timedelta(days=i * 7 + 7)
        week_end = now - timedelta(days=i * 7)

        count = sum(1 for c in checkins if week_start <= c < week_end)
        weeks.append(encode_days(count))

    return weeks


def get_days_since_last_visit(membership_id: int, db: Session) -> int:
    last = db.query(Attendance.checked_in).filter(
        Attendance.membershipID == membership_id
    ).order_by(Attendance.checked_in.desc()).first()

    if not last:
        return 365
    delta = datetime.now(timezone.utc).replace(tzinfo=None) - last.checked_in
    return delta.days


def get_days_until_expiry(membership: GymClientMembership) -> int:
    """Days remaining in the subscription"""
    today = datetime.now(timezone.utc).date()
    delta = membership.subscription_end - today
    return max(delta.days, 0)


async def predict_churn_risk(membership: GymClientMembership, db: Session, days: int):
    weeks = get_weekly_attendance(membership.id, db)

    # weights = list(range(1, 13))
    weighted_score = sum(weeks * np.array(range(1, 13)))
    recent_score = int(sum(weeks[8:] * np.array(range(9, 13))))
    old_score = int(sum(weeks[:8] * np.array(range(1, 9))))
    recent_vs_old = round(recent_score / (old_score + 1), 4)
    is_inactive = 1 if all(v == 0 for v in weeks[8:]) else 0

    days_since_last_visit = get_days_since_last_visit(membership.id, db)
    days_until_expiry = get_days_until_expiry(membership)

    payload = {
        "w0": weeks[0],  "w1": weeks[1],  "w2": weeks[2],
        "w3": weeks[3],  "w4": weeks[4],  "w5": weeks[5],
        "w6": weeks[6],  "w7": weeks[7],  "w8": weeks[8],
        "w9": weeks[9],  "w10": weeks[10], "w11": weeks[11],
        "days_since_last_visit": days_since_last_visit,
        "days_until_expiry"    : days_until_expiry,
    }

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.post(ML_API_URL, json=payload)
            response.raise_for_status()
            return response.json().get("churn_risk", "Low")
    except Exception as e:
        return f"Error  : {e}"
        # if  > 30 or days_until_expiry < 7:
        #     return "High"
        # elif recent_score <= 10:
        #     return "Mid"
        # return "Low"
