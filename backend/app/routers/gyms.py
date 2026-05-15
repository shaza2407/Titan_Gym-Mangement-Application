"""
app/routers/gyms.py
────────────────────
Endpoints:
  GET    /gyms/                        – list all active gyms
  POST   /gyms/                        – admin: create gym
  GET    /gyms/{gym_id}                – get gym + machines
  GET    /gyms/{gym_id}/machines       – list machines (filter by is_valid)
  POST   /gyms/{gym_id}/machines       – admin: add machine
  PATCH  /gyms/{gym_id}/machines/{id} – admin: update machine (mark valid/invalid)
  DELETE /gyms/{gym_id}/machines/{id} – admin: delete machine
"""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_session
from app.dependencies.auth import get_current_user, require_admin
from app.models.gym_machine import Gym, GymMachine
from app.schemas.gym_machine_schema import (
    GymCreate, GymResponse,
    MachineCreate, MachineUpdate, MachineResponse,
    GymWithMachines,
)

router = APIRouter(prefix="/gyms", tags=["Gyms & Machines"])


# ── Gyms ──────────────────────────────────────────────────────────────────────

@router.get("/", response_model=list[GymResponse], summary="List all active gyms")
async def list_gyms(db: AsyncSession = Depends(get_session)):
    result = await db.execute(select(Gym).where(Gym.is_active == True))
    return result.scalars().all()


@router.post(
    "/",
    response_model=GymResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Admin: create a gym",
)
async def create_gym(
    payload: GymCreate,
    _admin=Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    gym = Gym(**payload.model_dump())
    db.add(gym)
    await db.commit()
    await db.refresh(gym)
    return gym


@router.get("/{gym_id}", response_model=GymWithMachines, summary="Gym detail with machines")
async def get_gym(gym_id: int, db: AsyncSession = Depends(get_session)):
    result = await db.execute(select(Gym).where(Gym.gymID == gym_id))
    gym = result.scalar_one_or_none()
    if not gym:
        raise HTTPException(status_code=404, detail="Gym not found")

    machines_result = await db.execute(
        select(GymMachine).where(GymMachine.gymID == gym_id)
    )
    machines = machines_result.scalars().all()

    return GymWithMachines(
        gymID=gym.gymID,
        name=gym.name,
        location=gym.location,
        machines=machines,
    )


# ── Machines ──────────────────────────────────────────────────────────────────

@router.get(
    "/{gym_id}/machines",
    response_model=list[MachineResponse],
    summary="List machines for a gym (optionally filter by validity)",
)
async def list_machines(
    gym_id: int,
    valid_only: bool = Query(False, description="Return only is_valid=True machines"),
    db: AsyncSession = Depends(get_session),
):
    q = select(GymMachine).where(GymMachine.gymID == gym_id)
    if valid_only:
        q = q.where(GymMachine.is_valid == True)
    result = await db.execute(q)
    return result.scalars().all()


@router.post(
    "/{gym_id}/machines",
    response_model=MachineResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Admin: add a machine to a gym",
)
async def add_machine(
    gym_id: int,
    payload: MachineCreate,
    _admin=Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    # verify gym exists
    gym_result = await db.execute(select(Gym).where(Gym.gymID == gym_id))
    if not gym_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Gym not found")

    machine = GymMachine(gymID=gym_id, **payload.model_dump())
    db.add(machine)
    await db.commit()
    await db.refresh(machine)
    return machine


@router.patch(
    "/{gym_id}/machines/{machine_id}",
    response_model=MachineResponse,
    summary="Admin: update a machine (e.g. mark as invalid for maintenance)",
)
async def update_machine(
    gym_id: int,
    machine_id: int,
    payload: MachineUpdate,
    _admin=Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    result = await db.execute(
        select(GymMachine).where(
            GymMachine.machineID == machine_id,
            GymMachine.gymID     == gym_id,
        )
    )
    machine = result.scalar_one_or_none()
    if not machine:
        raise HTTPException(status_code=404, detail="Machine not found")

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(machine, field, value)

    await db.commit()
    await db.refresh(machine)
    return machine


@router.delete(
    "/{gym_id}/machines/{machine_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Admin: remove a machine",
)
async def delete_machine(
    gym_id: int,
    machine_id: int,
    _admin=Depends(require_admin),
    db: AsyncSession = Depends(get_session),
):
    result = await db.execute(
        select(GymMachine).where(
            GymMachine.machineID == machine_id,
            GymMachine.gymID     == gym_id,
        )
    )
    machine = result.scalar_one_or_none()
    if not machine:
        raise HTTPException(status_code=404, detail="Machine not found")

    await db.delete(machine)
    await db.commit()