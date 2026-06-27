from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date, timedelta, datetime, timezone
from dateutil.relativedelta import relativedelta
from app.database import get_session
from app.dependencies.auth import get_current_user

from app.schemas.admin.analytics_schemas import (
    AnalyticsSummaryResponse,
    RevenueTrendResponse,
    MemberGrowthResponse,
    MembershipDistributionResponse,
    WeeklyPatternResponse,
)

from app.services.admin.admin_analytics_service import (
    _verify_gym_owner, calc_revenue_for_period,
    get_revenue_change, get_all_active_members,
    get_active_members_this_month, get_avg_attendance_for_period,
    get_active_classes_for_period, get_revenue_for_last_6_months,
    get_members_for_last_6_months, get_membership_distribution,
    get_weekly_attendance_pattern, get_offer_details
)

router = APIRouter(prefix="/admin/analytics", tags=["Admin - Analytics"])



## /admin/analytics/{gym_id}/summary
@router.get("/{gym_id}/summary", response_model=AnalyticsSummaryResponse)
async def get_analytics_summary(gym_id: int, db: AsyncSession = Depends(get_session), current_admin=Depends(get_current_user)):
    gym = await _verify_gym_owner(gym_id, current_admin.userID, db)

    today = date.today()

    month_start = today.replace(day=1)
    prev_month_start = (month_start - relativedelta(months=1))
    prev_month_end = (month_start - timedelta(days=1))

    ## 1- Total Revenue This Month => new memberships * subscription price
    this_month_revenue = await calc_revenue_for_period(db, gym, month_start, today)
    revenue_change = await get_revenue_change(db, gym)

    ## 2- Active Members
    active_members = await get_all_active_members(db, gym.gymID)
    new_members_this_month = await get_active_members_this_month(db, gym)

    ## 3- Average Daily Attendance This Month
    avg_daily_attendance = await get_avg_attendance_for_period(db, gym, month_start, today)
    prev_avg = await get_avg_attendance_for_period(db, gym, prev_month_start, prev_month_end) or 1
    avg_attendance_change = round((avg_daily_attendance - prev_avg) / prev_avg * 100, 1)


    # 4- Active Classes
    active_classes = await get_active_classes_for_period(db, gym, month_start, today)
    prev_month_classes = await get_active_classes_for_period(db, gym, prev_month_start, prev_month_end)
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
    months = await get_revenue_for_last_6_months(db, gym)
    return months


## /admin/analytics/{gym_id}/member-trend
@router.get("/{gym_id}/member-trend", response_model=MemberGrowthResponse)
async def get_member_trend(gym_id: int, db: AsyncSession = Depends(get_session), current_admin=Depends(get_current_user)):
    gym = await _verify_gym_owner(gym_id, current_admin.userID, db)
    months = await get_members_for_last_6_months(db, gym)
    return months


## /admin/analytics/{gym_id}/membership-dist
@router.get("/{gym_id}/membership-dist", response_model=MembershipDistributionResponse)
async def get_membership_dist(gym_id: int, db: AsyncSession = Depends(get_session), current_admin=Depends(get_current_user)):
    gym = await _verify_gym_owner(gym_id, current_admin.userID, db)

    distribution = await get_membership_distribution(db, gym)
    return distribution


## /admin/analytics/{gym_id}/weekly-pattern
@router.get("/{gym_id}/weekly-pattern", response_model=WeeklyPatternResponse)
async def get_weekly_pattern(gym_id: int, db: AsyncSession = Depends(get_session), current_admin=Depends(get_current_user)):
    gym = await _verify_gym_owner(gym_id, current_admin.userID, db)
    data = await get_weekly_attendance_pattern(db, gym)
    return data


## Offer Retention
## /admin/analytics/{gym_id}/retention-offers/{offer_id}
@router.get("/{gym_id}/retention-offers/{offer_id}")
async def get_offer_details(gym_id: int, offer_id: int, db: AsyncSession = Depends(get_session), current_admin = Depends(get_current_user)):
    gym = await _verify_gym_owner(gym_id, current_admin.userID, db)
    data = await get_offer_details(db, gym, offer_id)
    return data