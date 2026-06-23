from pydantic import BaseModel
from typing import List


#1- Summary Analytics
class AnalyticsSummaryResponse(BaseModel):
    total_revenue: float
    revenue_change: float
    revenue_month: str
    active_members: int
    new_members_this_month: int
    avg_daily_attendance: int
    avg_attendance_change: float
    active_classes: int
    new_classes_this_month: int

#2- Revenue Trend
class MonthRevenue(BaseModel):
    month: str
    revenue: float
class RevenueTrendResponse(BaseModel):
    months: List[MonthRevenue]

#3- Member Growth
class MonthMembers(BaseModel):
    month: str
    total_members: int
class MemberGrowthResponse(BaseModel):
    months: List[MonthMembers]


#4- Membership Distribution
class MembershipTypeCount(BaseModel):
    type: str
    count: int
class MembershipDistributionResponse(BaseModel):
    distribution: List[MembershipTypeCount]

#5- Weekly Attendance Pattern
class DayPattern(BaseModel):
    day: str
    morning: int
    evening: int
class WeeklyPatternResponse(BaseModel):
    data: List[DayPattern]
