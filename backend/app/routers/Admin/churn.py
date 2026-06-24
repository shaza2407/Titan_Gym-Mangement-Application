import numpy as np
from datetime import datetime, timezone, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.attendance import Attendance
from app.models.gym_clients_membership import GymClientMembership
from app.ml.predictor import predict



def encode_days(days: int) -> int:
    if days <= 1:
        return 0   # low  : 0-1 days
    elif days <= 4:
        return 1   # mid  : 2-4 days
    else:
        return 2   # high : 5-7 days

async def get_weekly_attendance(client_id: int, gym_id: int, db: AsyncSession) -> list:
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    since_90 = now - timedelta(days=90)

    result = await db.execute(
        select(Attendance.checked_in).where(
            Attendance.clientID == client_id,
            Attendance.gymID == gym_id,
            Attendance.checked_in >= since_90,
        )
    )
    checkins = [row[0] for row in result.all()]

    weeks = []
    for i in range(11, -1, -1):
        week_start = now - timedelta(days=i * 7 + 7)
        week_end = now - timedelta(days=i * 7)
        count = sum(1 for c in checkins if week_start <= c < week_end)
        weeks.append(encode_days(count))

    return weeks


async def get_days_since_last_visit(client_id: int, gym_id: int, db: AsyncSession) -> int:
    result = await db.execute(
        select(Attendance.checked_in)
        .where(
            Attendance.clientID == client_id,
            Attendance.gymID == gym_id,
        )
        .order_by(Attendance.checked_in.desc())
    )
    last = result.first()

    if not last:
        return 365
    delta = datetime.now(timezone.utc).replace(tzinfo=None) - last.checked_in
    return delta.days


def get_days_until_expiry(membership: GymClientMembership) -> int:
    today = datetime.now(timezone.utc).date()
    delta = membership.subscription_end - today
    return max(delta.days, 0)

async def predict_churn_risk(membership: GymClientMembership, db: AsyncSession):
    weeks = await get_weekly_attendance(membership.id, db)

    days_since_last_visit = await get_days_since_last_visit(membership.id, db)
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
        return predict(payload)
    except Exception as e:
        return f"Error  : {e}"
        # if  > 30 or days_until_expiry < 7:
        #     return "High"
        # elif recent_score <= 10:
        #     return "Mid"
        # return "Low"
