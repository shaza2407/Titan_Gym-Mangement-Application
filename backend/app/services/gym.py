from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException, status
import qrcode
import base64
from io import BytesIO
from app.models.Gym import Gym
from app.schemas.gym import GymCreate, GymUpdate
from sqlalchemy import func
from datetime import date, datetime, timezone
from app.models.gym_clients_membership import GymClientMembership, ClientMembershipStatus
from app.models.attendance import Attendance

async def get_gym_by_admin(db: AsyncSession, gym_id: int, admin_id: int) -> Gym:
    result = await db.execute(select(Gym).filter(Gym.gymID == gym_id, Gym.adminID == admin_id))
    gym = result.scalars().first()
    if not gym:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Gym not found or does not belong to you.")
    return gym


async def get_all_gyms_by_admin(db: AsyncSession, admin_id: int, skip: int = 0, limit: int = 100) -> list[Gym]:
    result = await db.execute(select(Gym).filter(Gym.adminID == admin_id).offset(skip).limit(limit))
    return result.scalars().all()


async def create_gym(db: AsyncSession, gym_data: GymCreate, admin_id: int) -> Gym:
    data = gym_data.model_dump()
    data["adminID"] = admin_id
    data["QRCode"] = ""  
    new_gym = Gym(**data)
    try:
        db.add(new_gym)
        await db.flush()  
        new_gym.QRCode = generate_qr_code(new_gym.gymID, new_gym.gymName)
        await db.commit()
        await db.refresh(new_gym)
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Could not create gym.")
    return new_gym


async def update_gym(db: AsyncSession, gym_id: int, gym_data: GymUpdate, admin_id: int) -> Gym:
    gym = await get_gym_by_admin(db, gym_id, admin_id)
    updated_fields = gym_data.model_dump(exclude_unset=True)
    updated_fields.pop("adminID", None)
    for field, value in updated_fields.items():
        setattr(gym, field, value)
    try:
        await db.commit()
        await db.refresh(gym)
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Update failed.")
    return gym


async def delete_gym(db: AsyncSession, gym_id: int, admin_id: int) -> dict:
    gym = await get_gym_by_admin(db, gym_id, admin_id)
    await db.delete(gym)
    await db.commit()
    return {"detail": f"Gym with ID {gym_id} deleted successfully."}


def generate_qr_code(gym_id: int, gym_name: str) -> str:
    qr_data = f"TITAN-GYM-{gym_id}-{gym_name.upper().replace(' ', '-')}"
    qr = qrcode.make(qr_data)
    buffer = BytesIO()
    qr.save(buffer, format='PNG')
    qr_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
    return qr_base64

async def get_dashboard_stats(db: AsyncSession, gym_id: int, admin_id: int) -> dict:
    gym = await get_gym_by_admin(db, gym_id, admin_id)
    today = date.today()

    # Total members
    total = await db.execute(
        select(func.count(GymClientMembership.id))
        .filter(GymClientMembership.gymID == gym_id)
    )
    total_members = total.scalar() or 0

    # Active subscriptions
    active = await db.execute(
        select(func.count(GymClientMembership.id))
        .filter(
            GymClientMembership.gymID == gym_id,
            GymClientMembership.status == ClientMembershipStatus.active,
            GymClientMembership.subscription_end >= today,
        )
    )
    active_subscriptions = active.scalar() or 0

    # Today's attendance
    today_start = datetime(today.year, today.month, today.day, tzinfo=timezone.utc)
    attendance = await db.execute(
        select(func.count(Attendance.id))
        .join(GymClientMembership, Attendance.membershipID == GymClientMembership.id)
        .filter(
            GymClientMembership.gymID == gym_id,
            Attendance.checked_in >= today_start,
        )
    )
    today_attendance = attendance.scalar() or 0

    # Monthly revenue
    monthly = await db.execute(
        select(func.count(GymClientMembership.id))
        .filter(
            GymClientMembership.gymID == gym_id,
            GymClientMembership.status == ClientMembershipStatus.active,
            GymClientMembership.subscription_end >= today,
            GymClientMembership.subscription == "Monthly",
        )
    )
    annual = await db.execute(
        select(func.count(GymClientMembership.id))
        .filter(
            GymClientMembership.gymID == gym_id,
            GymClientMembership.status == ClientMembershipStatus.active,
            GymClientMembership.subscription_end >= today,
            GymClientMembership.subscription == "Annual",
        )
    )
    monthly_revenue = (
        (monthly.scalar() or 0) * (gym.subscriptionPrice or 0)
    ) + (
        (annual.scalar() or 0) * ((gym.yearlySubscriptionPrice or 0) / 12)
    )

    return {
        "gymID":               gym.gymID,
        "gymName":             gym.gymName,
        "totalMembers":        total_members,
        "activeSubscriptions": active_subscriptions,
        "todayAttendance":     today_attendance,
        "monthlyRevenue":      round(monthly_revenue, 2),
    }