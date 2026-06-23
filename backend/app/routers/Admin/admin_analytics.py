from fastapi import APIRouter, Depends, HTTPException, status
from pip._internal.operations.install import wheel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, cast, Date, extract, case, or_, and_
from datetime import date, timedelta
from dateutil.relativedelta import relativedelta
import pytz
from app.database import get_session
from app.dependencies.auth import get_current_user
from app.models import Admin, Subscription
from app.models.attendance import Attendance
from app.models import User, Admin, Coach
from app.models.Gym import Gym
from app.models.gym_clients_membership import GymClientMembership
from app.models.class_session import ClassSession
from app.models.class_enrollment import ClassEnrollment
from app.models.retention_offer import RetentionOfferRecipient
from app.models.client import Client

from app.schemas.admin.analytics_schemas import (
    AnalyticsSummaryResponse,
    RevenueTrendResponse,
    MemberGrowthResponse,
    MembershipDistributionResponse,
    WeeklyPatternResponse,
)

router = APIRouter(prefix="/admin/analytics", tags=["Admin - Analytics"])

## help function
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
        .join(GymClientMembership, Subscription.gymClientMebershipID == GymClientMembership.id)
        .where(
            GymClientMembership.gymID == gym.gymID,
            cast(Subscription.billingDate, Date) >= start_date,
            cast(Subscription.billingDate, Date) <= end_date,
        )
    )
    return result.scalar_one() or 0



## /admin/analytics/{gym_id}/summary
@router.get("/{gym_id}/summary", response_model=AnalyticsSummaryResponse)
async def get_analytics_summary(gym_id: int, db: AsyncSession = Depends(get_session), current_admin=Depends(get_current_user)):
    print("Analytics summary requested for gym_id:", gym_id)
    gym = await _verify_gym_owner(gym_id, current_admin.userID, db)
    print("finished _verify_gym_owner:", gym_id)
    today = date.today()
    month_start = today.replace(day=1)
    days_elapsed = today.day  # days from the 1st up to and including today
    prev_month_start = (month_start - relativedelta(months=1))
    prev_month_days = (month_start - timedelta(days=1)).day

    ## 1- Total Revenue This Month => new memberships * subscription price
    this_month_revenue = await calc_revenue_for_period(db, gym, month_start, today)
    last_month_revenue = await calc_revenue_for_period(db, gym, prev_month_start, month_start - relativedelta(days=1))

    last_month_revenue = last_month_revenue or 1
    revenue_change = round(((this_month_revenue - last_month_revenue) / last_month_revenue * 100), 2)

    ## 2- Active Members
    active_result = await db.execute(
        select(func.count(GymClientMembership.id)).where(
            GymClientMembership.gymID == gym.gymID,
            GymClientMembership.status == "active",
            GymClientMembership.subscription_end >= today,
        )
    )
    active_members = active_result.scalar_one_or_none() or 0

    new_this_month = await db.execute(
        select(func.count(GymClientMembership.id)).where(
            GymClientMembership.gymID == gym.gymID,
            GymClientMembership.status == "active",
            cast(GymClientMembership.joined_at, Date) >= month_start,
        )
    )
    new_members_this_month = new_this_month.scalar_one_or_none() or 0

    ## 3- Average Daily Attendance This Month
    checkins_result = await db.execute(
        select(func.count(Attendance.id))
        .join(GymClientMembership, Attendance.membershipID == GymClientMembership.id)
        .where(
            GymClientMembership.gymID == gym_id,
            cast(Attendance.checked_in, Date) >= month_start,
            cast(Attendance.checked_in, Date) <= today,
        )
    )
    total_checkins: int = checkins_result.scalar_one() or 0
    avg_daily_attendance = round(total_checkins / days_elapsed)

    prev_checkins_result = await db.execute(
        select(func.count(Attendance.id))
        .join(GymClientMembership, Attendance.membershipID == GymClientMembership.id)
        .where(
            GymClientMembership.gymID == gym_id,
            cast(Attendance.checked_in, Date) >= prev_month_start,
            cast(Attendance.checked_in, Date) < month_start,
        )
    )
    prev_avg = round((prev_checkins_result.scalar_one() or 0) / prev_month_days) or 1
    avg_attendance_change = round((avg_daily_attendance - prev_avg) / prev_avg * 100, 1)

    # 4- Active Classes
    active_classes_result = await db.execute(
        select(func.count(ClassSession.id)).where(
            ClassSession.gymID == gym_id,
            ClassSession.date >= month_start,
            ClassSession.date <= today,
        )
    )
    active_classes = active_classes_result.scalar_one_or_none() or 0

    prev_classes_result = await db.execute(
        select(func.count(ClassSession.id)).where(
            ClassSession.gymID == gym_id,
            ClassSession.date >= prev_month_start,
            ClassSession.date < month_start,
        )
    )
    prev_month_classes = prev_classes_result.scalar_one_or_none() or 0
    new_classes_this_month: int = active_classes - prev_month_classes
    print("return done for :", gym_id)

    return AnalyticsSummaryResponse(
        total_revenue=this_month_revenue,
        revenue_change=revenue_change,
        revenue_month=today.strftime("%B"),  # "June", "July"
        active_members=active_members,
        new_members_this_month=new_members_this_month,
        avg_daily_attendance=avg_daily_attendance,
        avg_attendance_change=avg_attendance_change,
        active_classes=active_classes,
        new_classes_this_month=new_classes_this_month,
    )

## /admin/analytics/{gym_id}/revenue-trend
@router.get("/{gym_id}/revenue-trend", response_model=RevenueTrendResponse)
async def get_revenue_trend(gym_id: int, db: AsyncSession = Depends(get_session), current_admin=Depends(get_current_user)):
    gym = await _verify_gym_owner(gym_id, current_admin.userID, db)

    today = date.today()
    months = []

    for i in range(6, -1, -1):
        month_date = today - relativedelta(months=i)
        start = month_date.replace(day=1)
        end = (start + relativedelta(months=1)) - relativedelta(days=1)

        revenue = await calc_revenue_for_period(db, gym, start, end)
        months.append({"month": start.strftime("%b"), "revenue": revenue})

    return RevenueTrendResponse(months=months)


## /admin/analytics/{gym_id}/member-trend
@router.get("/{gym_id}/member-trend", response_model=MemberGrowthResponse)
async def get_member_trend(gym_id: int, db: AsyncSession = Depends(get_session), current_admin=Depends(get_current_user)):
    gym = await _verify_gym_owner(gym_id, current_admin.userID, db)

    today = date.today()
    months = []
    for i in range(6, -1, -1):
        month_date = today - relativedelta(months=i)
        start = month_date.replace(day=1)
        end = (start + relativedelta(months=1)) - relativedelta(days=1)

        result = await db.execute(
            select(func.count(GymClientMembership.id)).where(
                GymClientMembership.gymID == gym.gymID,
                cast(GymClientMembership.joined_at, Date) >= start,
                cast(GymClientMembership.joined_at, Date) <= end,
            )
        )
        total = result.scalar_one() or 0
        months.append({"month": start.strftime("%b"), "total_members": total})
    return MemberGrowthResponse(months=months)

## /admin/analytics/{gym_id}/membership-dist
@router.get("/{gym_id}/membership-dist", response_model=MembershipDistributionResponse)
async def get_membership_dist(gym_id: int, db: AsyncSession = Depends(get_session), current_admin=Depends(get_current_user)):
    gym = await _verify_gym_owner(gym_id, current_admin.userID, db)

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

## /admin/analytics/{gym_id}/weekly-pattern
@router.get("/{gym_id}/weekly-pattern", response_model=WeeklyPatternResponse)
async def get_weekly_pattern(gym_id: int, db: AsyncSession = Depends(get_session), current_admin=Depends(get_current_user)):
    gym = await _verify_gym_owner(gym_id, current_admin.userID, db)

    today = date.today()
    week_start = today - timedelta(days=6)
    result = await db.execute(
        select(
            cast(Attendance.checked_in, Date).label("day"),
            extract("hour", Attendance.checked_in).label("hour"),
            func.count(Attendance.id).label("cnt"),
        ).join(GymClientMembership, Attendance.membershipID == GymClientMembership.id)
        .where(
            GymClientMembership.gymID == gym_id,
            cast(Attendance.checked_in, Date) >= week_start,
            cast(Attendance.checked_in, Date) <= today,
        ).group_by(cast(Attendance.checked_in, Date), extract("hour", Attendance.checked_in))
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
    }for i in range(7)]

    return WeeklyPatternResponse(data=data)