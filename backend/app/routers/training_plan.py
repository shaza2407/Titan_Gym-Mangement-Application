# app/routers/training_plan.py
"""
Endpoints
─────────
POST   /training-plans/generate    – AI generates a new plan
GET    /training-plans/            – List all plans for the current client
GET    /training-plans/{plan_id}   – Full detail of a specific plan
PATCH  /training-plans/{plan_id}/complete – Mark plan as completed
DELETE /training-plans/{plan_id}   – Delete a plan

BUG FIXES:
1. All routes now use require_client — previously any authenticated user
   (coach, admin) could generate/read/delete plans.
2. Added PATCH /complete endpoint to properly set PlanStatus.COMPLETED and
   completed_at timestamp.  The goal_crusher achievement depends on this.
   Without it the status column stays IN_PROGRESS forever.
3. TrainingPlanResponse schema was missing `status` and `completed_at` fields;
   added TrainingPlanSummary missing `status` too.
4. _rebuild_weeks was called but not guarded against non-JSON plan_json;
   wrapped in try/except with a clear 500 message.
5. DELETE was missing await db.commit() after delete — data was never removed.
   (Already had it — kept as-is but confirmed.)
"""

import json
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_session
from app.dependencies.auth import get_current_user, require_client
from app.models.training_plan import TrainingPlan, PlanStatus
from app.models.client import Client
from app.schemas.TraingPlanRequest import TrainingPlanRequest
from app.schemas.TraingPlanResponse import (
    TrainingPlanResponse,
    TrainingPlanSummary,
    WeekPlan,
    DayPlan,
)
from app.services.gemini_agent import gemini_agent

router = APIRouter(prefix="/training-plans", tags=["AI Training Plans"])


# ── Helper ────────────────────────────────────────────────────────────────────

async def _get_client_id(current_user, db: AsyncSession) -> int:
    result = await db.execute(select(Client).where(Client.userID == int(current_user.userID)))
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                            detail="Only clients can access training plans.")
    return client.clientID


async def _get_owned_plan(plan_id: int, client_id: int, db: AsyncSession) -> TrainingPlan:
    result = await db.execute(
        select(TrainingPlan).where(
            TrainingPlan.planID   == plan_id,
            TrainingPlan.clientID == client_id,
        )
    )
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="Training plan not found.")
    return plan


# ── POST /training-plans/generate ────────────────────────────────────────────

@router.post(
    "/generate",
    response_model=TrainingPlanResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Generate a personalised AI training plan",
)
async def generate_training_plan(
    req: TrainingPlanRequest,
    # BUG FIX: use require_client so coaches/admins are rejected at the gate
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)
    try:
        plan = await gemini_agent.generate_plan(client_id=client_id, req=req, db=db)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except RuntimeError as exc:
        raise HTTPException(status_code=502, detail=str(exc))
    return plan


# ── GET /training-plans/ ──────────────────────────────────────────────────────

@router.get(
    "/",
    response_model=list[TrainingPlanSummary],
    summary="List all training plans for the authenticated client",
)
async def list_training_plans(
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)
    result = await db.execute(
        select(TrainingPlan)
        .where(TrainingPlan.clientID == client_id)
        .order_by(TrainingPlan.created_at.desc())
    )
    return result.scalars().all()


# ── GET /training-plans/{plan_id} ─────────────────────────────────────────────

@router.get(
    "/{plan_id}",
    response_model=TrainingPlanResponse,
    summary="Get full detail of a specific training plan",
)
async def get_training_plan(
    plan_id: int,
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)
    plan_row  = await _get_owned_plan(plan_id, client_id, db)

    # BUG FIX: guard against corrupt / missing JSON
    try:
        plan_dict    = json.loads(plan_row.plan_json)
        weeks_parsed = _rebuild_weeks(plan_dict.get("plan", []))
    except (json.JSONDecodeError, TypeError):
        raise HTTPException(status_code=500, detail="Stored plan data is corrupt.")

    return TrainingPlanResponse(
        planID       = plan_row.planID,
        clientID     = plan_row.clientID,
        title        = plan_row.title,
        goal         = plan_row.goal,
        level        = plan_row.level,
        weeks        = plan_row.weeks,
        status       = plan_row.status,
        completed_at = plan_row.completed_at,
        plan         = weeks_parsed,
        raw_json     = plan_row.plan_json,
        created_at   = plan_row.created_at,
    )


# ── PATCH /training-plans/{plan_id}/complete ─────────────────────────────────
# BUG FIX: This endpoint was completely missing.
# Without it the goal_crusher achievement could never advance because
# plan.status would always remain IN_PROGRESS.

@router.patch(
    "/{plan_id}/complete",
    response_model=TrainingPlanSummary,
    summary="Mark a training plan as completed",
)
async def complete_training_plan(
    plan_id: int,
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)
    plan_row  = await _get_owned_plan(plan_id, client_id, db)

    if plan_row.status == PlanStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Plan is already completed.")

    plan_row.status       = PlanStatus.COMPLETED
    plan_row.completed_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(plan_row)
    return plan_row


# ── DELETE /training-plans/{plan_id} ─────────────────────────────────────────

@router.delete(
    "/{plan_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a training plan",
)
async def delete_training_plan(
    plan_id: int,
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)
    plan_row  = await _get_owned_plan(plan_id, client_id, db)
    await db.delete(plan_row)
    await db.commit()


# ── Local helper ──────────────────────────────────────────────────────────────

def _rebuild_weeks(weeks_list: list) -> list[WeekPlan]:
    result = []
    for w in weeks_list:
        days = [
            DayPlan(
                day       = d.get("day", ""),
                focus     = d.get("focus", ""),
                exercises = d.get("exercises", []),
                notes     = d.get("notes"),
            )
            for d in w.get("days", [])
        ]
        result.append(WeekPlan(week=w.get("week", 0), theme=w.get("theme"), days=days))
    return result
