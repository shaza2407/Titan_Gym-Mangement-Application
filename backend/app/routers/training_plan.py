"""
routers/training_plan.py
────────────────────────
Endpoints:
  POST /training-plans/generate          – AI generates a new plan for the current client
  GET  /training-plans/                  – List all plans for the current client
  GET  /training-plans/{plan_id}         – Retrieve a specific plan (full detail)
  DELETE /training-plans/{plan_id}       – Delete a plan

All routes require a valid JWT token (client role).
"""

import json
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_session
from app.dependencies.auth import get_current_user       # existing JWT dependency
from app.models.training_plan import TrainingPlan
from app.models.client import Client
from app.schemas.TraingPlanRequest import (
    TrainingPlanRequest,
)
from app.schemas.TraingPlanResponse import (
    TrainingPlanResponse,
    TrainingPlanSummary,
    WeekPlan,
    DayPlan,
)
from app.services.gemini_agent import gemini_agent

router = APIRouter(prefix="/training-plans", tags=["AI Training Plans"])


# ── Helper: resolve clientID from authenticated user ──────────────────────────

async def _get_client_id(current_user: dict, db: AsyncSession) -> int:
    """
    Looks up the Client record linked to the authenticated user.
    Raises 403 if the user is not a client.
    """
    user_id = current_user.userID
    result  = await db.execute(select(Client).where(Client.userID == int(user_id)))
    client  = result.scalar_one_or_none()
    if not client:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only clients can access training plans."
        )
    return client.clientID


# ── POST /training-plans/generate ────────────────────────────────────────────

@router.post(
    "/generate",
    response_model=TrainingPlanResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Generate a personalised AI training plan",
    description=(
        "Calls the Gemini AI agent to create a structured multi-week training programme "
        "based on the client's profile and the supplied parameters. "
        "The plan is persisted in the database and returned in full."
    ),
)
async def generate_training_plan(
    req: TrainingPlanRequest,
    current_user: dict   = Depends(get_current_user),
    db: AsyncSession     = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)

    try:
        plan = await gemini_agent.generate_plan(
            client_id=client_id,
            req=req,
            db=db,
        )
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
    current_user: dict = Depends(get_current_user),
    db: AsyncSession   = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)

    result = await db.execute(
        select(TrainingPlan)
        .where(TrainingPlan.clientID == client_id)
        .order_by(TrainingPlan.created_at.desc())
    )
    plans = result.scalars().all()
    return plans


# ── GET /training-plans/{plan_id} ─────────────────────────────────────────────

@router.get(
    "/{plan_id}",
    response_model=TrainingPlanResponse,
    summary="Get full detail of a specific training plan",
)
async def get_training_plan(
    plan_id: int,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession   = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)

    result = await db.execute(
        select(TrainingPlan).where(
            TrainingPlan.planID    == plan_id,
            TrainingPlan.clientID  == client_id,
        )
    )
    plan_row = result.scalar_one_or_none()
    if not plan_row:
        raise HTTPException(status_code=404, detail="Training plan not found.")

    # Rebuild typed structure from stored JSON
    plan_dict   = json.loads(plan_row.plan_json)
    weeks_parsed = _rebuild_weeks(plan_dict.get("plan", []))

    return TrainingPlanResponse(
        planID     = plan_row.planID,
        clientID   = plan_row.clientID,
        title      = plan_row.title,
        goal       = plan_row.goal,
        level      = plan_row.level,
        weeks      = plan_row.weeks,
        plan       = weeks_parsed,
        raw_json   = plan_row.plan_json,
        created_at = plan_row.created_at,
    )


# ── DELETE /training-plans/{plan_id} ─────────────────────────────────────────

@router.delete(
    "/{plan_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a training plan",
)
async def delete_training_plan(
    plan_id: int,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession   = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)

    result = await db.execute(
        select(TrainingPlan).where(
            TrainingPlan.planID    == plan_id,
            TrainingPlan.clientID  == client_id,
        )
    )
    plan_row = result.scalar_one_or_none()
    if not plan_row:
        raise HTTPException(status_code=404, detail="Training plan not found.")

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
