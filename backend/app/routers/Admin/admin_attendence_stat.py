from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, cast, Date
from datetime import date, timedelta

from app.database import get_session
from app.dependencies.auth import get_current_user
from app.models.attendance import Attendance
from app.models.gym_clients_membership import GymClientMembership
from app.models.Gym import Gym
from app.schemas.attendance_schema import (
    AttendanceStatsResponse,
    WeeklyAttendanceResponse,
    QRCodeResponse,
)

router = APIRouter(prefix="/admin/attendance", tags=["Admin – Attendance"])


## help function
async def _varify_gym_owner(gym_id: int, admin_id: int, db: AsyncSession) -> Gym:
    print("//////////////  HERE 2  //////////////")
    result = await db.execute(select(Gym).where(Gym.gymID == gym_id, Gym.adminID == admin_id))
    gym = result.scalar_one_or_none()
    if not gym:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Gym not found")
    return gym


## "/admin/attendance/{gym_id}/stats"
@router.get("/{gym_id}/stats", response_model=AttendanceStatsResponse)
async def get_attendance_stats(gym_id: int, db: AsyncSession = Depends(get_session), current_admin = Depends(get_current_user)):
    print("//////////////  HERE 1  //////////////")
    await _varify_gym_owner(gym_id, current_admin.userID, db)

    today = date.today()
    week_start = today - timedelta(days=6)


    ## 1-Today's total
    today_result = await db.execute(
        select(func.count(Attendance.id))
        .join(GymClientMembership, Attendance.membershipID == GymClientMembership.id)
        .where(GymClientMembership.gymID == gym_id,
               cast(Attendance.checked_in, Date) == today,
               )
    )
    today_total = today_result.scalar_one_or_none() or 0


    ## 2-This week total
    week_result = await db.execute(
        select(func.count(Attendance.id))
        .join(GymClientMembership, Attendance.membershipID == GymClientMembership.id)
        .where(GymClientMembership.gymID == gym_id,
               cast(Attendance.checked_in, Date) >= week_start,
               )
    )
    week_total = week_result.scalar_one_or_none() or 0

    return AttendanceStatsResponse(
        today_total=today_total,
        this_week=week_total,
    )



## "/admin/attendance/{gym_id}/qr-code"
@router.get("/{gym_id}/qr-code", response_model=QRCodeResponse)
async def get_qr_code(gym_id: int, db: AsyncSession = Depends(get_session), current_admin = Depends(get_current_user)):
    gym = await _varify_gym_owner(gym_id, current_admin.userID, db)
    qr_id = gym.QRCode or f"TITAN-FIT-{gym_id:03d}"
    return QRCodeResponse(
        gym_id=gym_id,
        qr_identifier=qr_id,
        gym_name=gym.gymName,
    )

## "/admin/attendance/{gym_id}/weekly"
@router.get("/{gym_id}/weekly", response_model=WeeklyAttendanceResponse)
async def get_weekly_attendance(gym_id: int, db: AsyncSession = Depends(get_session), current_admin = Depends(get_current_user)):
    await _varify_gym_owner(gym_id, current_admin.userID, db)

    today = date.today()
    week_start = today - timedelta(days=6)

    result = await db.execute(
        select(
            cast(Attendance.checked_in, Date).label("day"),
            func.count(Attendance.id).label("count"),
        )
        .join(GymClientMembership, Attendance.membershipID == GymClientMembership.id)
        .where(
            GymClientMembership.gymID == gym_id,
            cast(Attendance.checked_in, Date) >= week_start,
        )
        .group_by(cast(Attendance.checked_in, Date))
        .order_by(cast(Attendance.checked_in, Date))
    )
    rows = result.all()
    count_map = {r.day: r.count for r in rows}
    days = [
        {
            "day": (week_start + timedelta(days=i)).strftime("%a"),
            "count": count_map.get(week_start + timedelta(days=i), 0)
        }
        for i in range(7)
    ]

    return WeeklyAttendanceResponse(week_start=str(week_start), days=days)