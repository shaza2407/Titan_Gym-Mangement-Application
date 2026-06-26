from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.dependencies.auth import get_current_user
from app.schemas.client.attendance_schema import (
    AttendanceStatsResponse,
    WeeklyAttendanceResponse,
    QRCodeResponse,
)

from app.services.admin.admin_analytics_service import _verify_gym_owner

from app.services.admin.admin_attendance_service import (
    get_attendance_statistics, get_weekly_attendance_chart
)


router = APIRouter(prefix="/admin/attendance", tags=["Admin – Attendance"])


## "/admin/attendance/{gym_id}/stats"
@router.get("/{gym_id}/stats", response_model=AttendanceStatsResponse)
async def get_attendance_stats(gym_id: int, db: AsyncSession = Depends(get_session), current_admin=Depends(get_current_user)):
    gym = await _verify_gym_owner(gym_id, current_admin.userID, db)
    stats = await get_attendance_statistics(db, gym)
    return stats



## "/admin/attendance/{gym_id}/qr-code"
@router.get("/{gym_id}/qr-code", response_model=QRCodeResponse)
async def get_qr_code(gym_id: int, db: AsyncSession = Depends(get_session), current_admin = Depends(get_current_user)):
    gym = await _verify_gym_owner(gym_id, current_admin.userID, db)
    qr_id = gym.QRCode or f"TITAN-FIT-{gym_id:03d}"
    return QRCodeResponse(
        gym_id=gym_id,
        qr_identifier=qr_id,
        gym_name=gym.gymName,
    )

## "/admin/attendance/{gym_id}/weekly"
@router.get("/{gym_id}/weekly", response_model=WeeklyAttendanceResponse)
async def get_weekly_attendance(gym_id: int, db: AsyncSession = Depends(get_session), current_admin=Depends(get_current_user)):
    gym = await _verify_gym_owner(gym_id, current_admin.userID, db)
    weekly_attendance = await get_weekly_attendance_chart(db, gym)
    return weekly_attendance
