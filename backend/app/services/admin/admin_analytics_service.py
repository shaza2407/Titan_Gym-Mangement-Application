from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, cast, Date, extract, case, or_, and_
from datetime import date, timedelta
from dateutil.relativedelta import relativedelta
from app.models import Admin, Subscription, RetentionOffer
from app.models.attendance import Attendance
from app.models import User, Admin, Coach
from app.models.Gym import Gym
from app.models.gym_clients_membership import GymClientMembership
from app.models.class_session import ClassSession
from app.models.retention_offer import RetentionOfferRecipient
from app.models.client import Client

from app.schemas.admin.analytics_schemas import (
    RevenueTrendResponse,
    MemberGrowthResponse,
    MembershipDistributionResponse,
    WeeklyPatternResponse,
)

async def _verify_gym_owner(gym_id: int, user_id: int, db: AsyncSession) -> Gym:
    result = await db.execute(select(Admin).where(Admin.userID == user_id))
    admin = result.scalar_one_or_none()
    if not admin:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Admin not found")

    result = await db.execute(select(Gym).where(Gym.gymID == gym_id, Gym.adminID == admin.adminID))
    gym = result.scalar_one_or_none()
    if not gym:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Gym not found")

    return gym


async def calc_revenue_for_period(db: AsyncSession, gym: Gym, start_date: date, end_date: date) -> float:
    result = await db.execute(
        select(func.sum(Subscription.supscriptionPrice * Subscription.duration_count))
        .where(
            Subscription.gymID == gym.gymID,
            cast(Subscription.billingDate, Date) >= start_date,
            cast(Subscription.billingDate, Date) <= end_date,
        )
    )
    return result.scalar_one() or 0

async def get_revenue_change(db: AsyncSession, gym: Gym) -> float:
    today = date.today()

    month_start = today.replace(day=1)
    prev_month_start = (month_start - relativedelta(months=1))

    ## 1- Total Revenue This Month => new memberships * subscription price
    this_month_revenue = await calc_revenue_for_period(db, gym, month_start, today)
    last_month_revenue = await calc_revenue_for_period(db, gym, prev_month_start, month_start - relativedelta(days=1))

    last_month_revenue = last_month_revenue or 1
    revenue_change = round(((this_month_revenue - last_month_revenue) / last_month_revenue * 100), 2)
    return revenue_change


async def get_all_active_members(db: AsyncSession, gym_id: int):
    today = date.today()

    ## 2- Active Members
    active_result = await db.execute(
        select(func.count(GymClientMembership.id)).where(
            GymClientMembership.gymID == gym_id,
            GymClientMembership.status == "active",
            GymClientMembership.subscription_end >= today,
        )
    )
    active_members = active_result.scalar_one_or_none() or 0
    return active_members


async def get_active_members_this_month(db: AsyncSession, gym: Gym):
    today = date.today()
    month_start = today.replace(day=1)

    new_this_month = await db.execute(
        select(func.count(GymClientMembership.id)).where(
            GymClientMembership.gymID == gym.gymID,
            GymClientMembership.status == "active",
            cast(GymClientMembership.joined_at, Date) >= month_start,
        )
    )
    return new_this_month.scalar_one_or_none() or 0



async def get_members_for_period(db: AsyncSession, gym: Gym, start_date: date, end_date: date):
    new_this_month = await db.execute(
        select(func.count(GymClientMembership.id)).where(
            GymClientMembership.gymID == gym.gymID,
            cast(GymClientMembership.joined_at, Date) >= start_date,
            cast(GymClientMembership.joined_at, Date) <= end_date,
        )
    )
    return new_this_month.scalar_one_or_none() or 0


async def get_avg_attendance_for_period(db: AsyncSession, gym: Gym, start_date: date, end_date: date):
    checkins_result = await db.execute(
        select(func.count(Attendance.id))
        .where(
            Attendance.gymID == gym.gymID,
            cast(Attendance.checked_in, Date) >= start_date,
            cast(Attendance.checked_in, Date) <= end_date,
        )
    )
    total_checkins: int = checkins_result.scalar_one() or 0
    days = (end_date - start_date).days + 1
    avg_daily_attendance = round(total_checkins / days)
    return avg_daily_attendance


async def get_active_classes_for_period(db: AsyncSession, gym: Gym, start_date: date, end_date: date):
    active_classes_result = await db.execute(
        select(func.count(ClassSession.id)).where(
            ClassSession.gymID == gym.gymID,
            or_(
                # One-time classes: date falls within the period
                and_(
                    ClassSession.date.isnot(None),
                    ClassSession.date >= start_date,
                    ClassSession.date <= end_date,
                ),
                # Recurring classes: always active regardless of period
                ClassSession.day_of_week.isnot(None),
            ),
        )
    )
    return active_classes_result.scalar_one_or_none() or 0


async def get_revenue_for_last_6_months(db: AsyncSession, gym: Gym):
    today = date.today()
    months = []

    for i in range(5, -1, -1):
        month_date = today - relativedelta(months=i)
        start = month_date.replace(day=1)
        end = (start + relativedelta(months=1)) - relativedelta(days=1)

        revenue = await calc_revenue_for_period(db, gym, start, end)
        months.append({"month": start.strftime("%b"), "revenue": revenue})

    return RevenueTrendResponse(months=months)


async def get_members_for_last_6_months(db: AsyncSession, gym: Gym):
    today = date.today()
    months = []
    for i in range(5, -1, -1):
        month_date = today - relativedelta(months=i)
        start = month_date.replace(day=1)
        end = (start + relativedelta(months=1)) - relativedelta(days=1)

        total = await get_members_for_period(db, gym, start, end)
        months.append({"month": start.strftime("%b"), "total_members": total})
    return MemberGrowthResponse(months=months)


async def get_membership_distribution(db: AsyncSession, gym: Gym):
    result = await db.execute(
        select(GymClientMembership.subscription.label("type"),
               func.count(GymClientMembership.id).label("count"))
        .where(
            GymClientMembership.gymID == gym.gymID,
            GymClientMembership.status == "active",
        ).group_by(GymClientMembership.subscription)
    )
    rows = result.all()
    distribution = [{"type": r.type, "count": r.count} for r in rows]
    return MembershipDistributionResponse(distribution=distribution)


async def get_weekly_attendance_pattern(db: AsyncSession, gym: Gym):
    today = date.today()
    week_start = today - timedelta(days=6)
    result = await db.execute(
        select(
            cast(Attendance.checked_in, Date).label("day"),
            extract("hour", Attendance.checked_in).label("hour"),
            func.count(Attendance.id).label("cnt"),
        ).where(
            Attendance.gymID == gym.gymID,
            cast(Attendance.checked_in, Date) >= week_start,
            cast(Attendance.checked_in, Date) <= today,
        ).group_by(
            cast(Attendance.checked_in, Date),
            extract("hour", Attendance.checked_in),
        )
    )

    rows = result.all()
    day_names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    morning: dict[str, int] = {d: 0 for d in day_names}
    evening: dict[str, int] = {d: 0 for d in day_names}

    for r in rows:
        day_offset = (r.day - week_start).days
        if 0 <= day_offset < 7:
            label = (week_start + timedelta(days=day_offset)).strftime("%a")
            # label = r.day.strftime("%a")
            if int(r.hour) < 12:
                morning[label] += r.cnt
            else:
                evening[label] += r.cnt
    data = [{
        "day": (week_start + timedelta(days=i)).strftime("%a"),
        "morning": morning[(week_start + timedelta(days=i)).strftime("%a")],
        "evening": evening[(week_start + timedelta(days=i)).strftime("%a")],
    } for i in range(7)]

    return WeeklyPatternResponse(data=data)


async def get_offer_details_service(db: AsyncSession, gym: Gym, offer_id: int):

    result = await db.execute(select(RetentionOffer).where(
            RetentionOffer.id == offer_id,
            RetentionOffer.gymId == gym.gymID)
    )
    offer = result.scalar_one_or_none()
    if not offer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Offer not found")

    recipients_result = await db.execute(
        select(User.name, User.email, RetentionOfferRecipient.risk_level)
        .join(GymClientMembership, RetentionOfferRecipient.membership_id == GymClientMembership.id)
        .join(Client, GymClientMembership.clientID == Client.clientID)
        .join(User, Client.userID == User.userID)
        .where(RetentionOfferRecipient.offer_id == offer_id)
    )

    recipients = [
        {"name": r.name, "email": r.email, "risk_level": r.risk_level}
        for r in recipients_result.all()
    ]

    return {
        "id":offer.id,
        "title":offer.title,
        "offer_type":offer.offer_type,
        "description":offer.description,
        "benefit":offer.benefit,
        "valid_until":offer.valid_until.isoformat() if offer.valid_until else None,
        "target_type":offer.target_type,
        "number_of_members":offer.number_of_members,
        "sent_at":offer.created_at.isoformat() if offer.created_at else None,
        "recipients": recipients,
    }