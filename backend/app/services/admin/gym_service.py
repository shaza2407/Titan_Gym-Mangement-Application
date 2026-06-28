from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException, status
import qrcode
import base64
from io import BytesIO
from sqlalchemy import delete, or_, and_
import calendar
from app.schemas.admin.gym import GymCreate, GymUpdate
from sqlalchemy import func
from datetime import date, datetime
from app.models.gym_clients_membership import GymClientMembership, ClientMembershipStatus
from app.models.attendance import Attendance
from app.models.gym_coachs_membership import GymCoachMembership
from app.models import Admin
from app.models import Gym , GymMachineInventory
from app.models.class_session import ClassSession
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select
from fastapi import HTTPException



#get gyms creted by sepecified admin

async def get_gym_by_admin(db: AsyncSession, gym_id: int, admin_id: int) -> Gym:
    result = await db.execute(
        select(Gym)
        .options(selectinload(Gym.machine_inventory))
        .filter(Gym.gymID == gym_id, Gym.adminID == admin_id)
    )
    gym = result.scalars().first()
    if not gym:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Gym not found or does not belong to you.")
    return gym


async def get_all_gyms_by_admin(db: AsyncSession, admin_id: int, skip: int = 0, limit: int = 100) -> list[Gym]:
    result = await db.execute(
        select(Gym)
        .options(selectinload(Gym.machine_inventory))
        .filter(Gym.adminID == admin_id)
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()



async def create_gym(db: AsyncSession, gym_data: GymCreate, admin_id: int) -> Gym:
    data = gym_data.model_dump()
    machines = data.pop("machines", [])
    data["adminID"] = admin_id
    data["QRCode"] = ""
    new_gym = Gym(**data)
    try:
        db.add(new_gym)
        await db.flush()
        new_gym.QRCode = generate_qr_code(new_gym.gymID, new_gym.gymName)

        for machine in machines:
            inventory = GymMachineInventory(
                gymID=new_gym.gymID,
                machineName=machine["machineName"],
                machineType=machine["machineType"],
                quantity=machine["quantity"],
            )
            db.add(inventory)

        await db.commit()

        result = await db.execute(
            select(Gym)
            .options(selectinload(Gym.machine_inventory))
            .filter(Gym.gymID == new_gym.gymID)
        )
        new_gym = result.scalars().first()

    except IntegrityError:
        await db.rollback()
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Could not create gym.")
    return new_gym

async def update_gym(db: AsyncSession, gym_id: int, gym_data: GymUpdate, admin_id: int) -> Gym:
    gym = await get_gym_by_admin(db, gym_id, admin_id)
    
    updated_fields = gym_data.model_dump(exclude_unset=True)
    updated_fields.pop("adminID", None)
    
    # Handle machines separately
    machines = updated_fields.pop("machines", None)
    
    # Update basic gym fields
    for field, value in updated_fields.items():
        setattr(gym, field, value)
    
    # Replace machines if provided
    if machines is not None:
        # Delete existing machines for this gym
        await db.execute(
            delete(GymMachineInventory).where(GymMachineInventory.gymID == gym_id)
        )
        # Add new machines
        for machine in machines:
            new_inventory = GymMachineInventory(
                gymID=gym_id,
                machineName=machine["machineName"],
                machineType=machine["machineType"],
                quantity=machine["quantity"],
            )
            db.add(new_inventory)
    try:
        await db.commit()
        result = await db.execute(
            select(Gym)
            .options(selectinload(Gym.machine_inventory))
            .filter(Gym.gymID == gym_id)
        )
        gym = result.scalars().first()
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


#for gym dashboard screen
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
    today_start = datetime(today.year, today.month, today.day)
    attendance = await db.execute(
        select(func.count(Attendance.id)).filter(
            Attendance.gymID == gym_id,
            Attendance.checked_in >= today_start,
        )
    )
    today_attendance = attendance.scalar() or 0

    today = date.today()
    today_day = calendar.day_name[today.weekday()].lower()  #ex. monday

    classes = await db.execute(
    select(func.count(ClassSession.id))
    .filter(
        ClassSession.gymID == gym_id,
        or_(
            ClassSession.date == today,                    #for only one time classes
            and_(
                ClassSession.is_recurring == True,
                ClassSession.day_of_week == today_day,     #for recurring classes
            )
            )
        )
    )
    total_classes = classes.scalar() or 0
    return {
        "gymID":               gym.gymID,
        "gymName":             gym.gymName,
        "totalMembers":        total_members,
        "activeSubscriptions": active_subscriptions,
        "todayAttendance":     today_attendance,
        "totalClasses":        total_classes,
    }



async def get_total_members(db: AsyncSession, user_id: int) -> int:
    admin_result = await db.execute(
        select(Admin).where(Admin.userID == user_id)
    )
    admin = admin_result.scalars().first()

    if not admin:
        raise HTTPException(status_code=403, detail="User is not an admin")

    result = await db.execute(
        select(func.count(GymClientMembership.id))
        .join(Gym, GymClientMembership.gymID == Gym.gymID)
        .where(Gym.adminID == admin.adminID)
    )
    return result.scalar() or 0


async def get_member_count(db: AsyncSession, gym_id: int) -> int:
    result = await db.execute(
        select(func.count(GymClientMembership.id))
        .where(
            GymClientMembership.gymID == gym_id,
            GymClientMembership.status == ClientMembershipStatus.active,
        )
    )
    return result.scalar() or 0


async def get_coach_count(db: AsyncSession, gym_id: int) -> int:
    result = await db.execute(
        select(func.count(GymCoachMembership.id))
        .where(GymCoachMembership.gymID == gym_id)
    )
    return result.scalar() or 0

async def get_class_count(db: AsyncSession, gym_id: int) -> int:
    today = date.today()
    today_day = calendar.day_name[today.weekday()].lower()
    result = await db.execute(
        select(func.count (ClassSession.id))
        .where(ClassSession.gymID == gym_id,
               or_(ClassSession.day_of_week == today_day ,
                   ClassSession.date == today))
    )
    return result.scalar() or 0