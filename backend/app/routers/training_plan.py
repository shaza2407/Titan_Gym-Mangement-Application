"""
app/routers/training_plan.py
─────────────────────────────
Endpoints
─────────
POST   /training-plans/generate           – AI generates a new plan
GET    /training-plans/                   – List active plans for the client
GET    /training-plans/{id}               – Full plan detail
GET    /training-plans/{id}/versions      – All versions of a plan chain
PATCH  /training-plans/{id}               – Edit (creates new version, never overwrites)
POST   /training-plans/{id}/duplicate     – Clone plan
POST   /training-plans/{id}/complete-day  – Mark a day's workout done
PATCH  /training-plans/{id}/complete      – Mark entire plan completed
DELETE /training-plans/{id}               – Soft-delete (set is_active = False)
GET    /training-plans/{id}/pdf           – Download plan as PDF
"""

import json
from datetime import date, datetime, timezone
from typing import Optional, List
from io import BytesIO

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_session
from app.dependencies.auth import require_client
from app.models.client import Client
from app.models.training_plan import (
    TrainingPlan, PlanStatus,
    TrainingPlanTracking, WorkoutStatus,
    TrainingPlanWeekProgress, DayStatus,
)
from app.schemas.TrainingPlanRequest import TrainingPlanRequest
from app.schemas.TrainingPlanResponse import (
    TrainingPlanResponse, TrainingPlanSummary, WeekPlan, DayPlan,
)
from app.services.gemini_agent import gemini_agent
from app.services.achievement_engine import achievement_engine

router = APIRouter(prefix="/training-plans", tags=["AI Training Plans"])


# ── Helpers ───────────────────────────────────────────────────────────────────

async def _get_client_id(current_user, db: AsyncSession) -> int:
    result = await db.execute(select(Client).where(Client.userID == int(current_user.userID)))
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(status_code=403, detail="Only clients can access training plans.")
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


def _parse_plan_json(plan: TrainingPlan) -> list[WeekPlan]:
    try:
        data  = json.loads(plan.plan_json)
        weeks = data.get("plan", [])
        return [
            WeekPlan(
                week  = w.get("week", 0),
                theme = w.get("theme"),
                days  = [
                    DayPlan(
                        day       = d.get("day", ""),
                        focus     = d.get("focus", ""),
                        exercises = d.get("exercises", []),
                        notes     = d.get("notes"),
                    )
                    for d in w.get("days", [])
                ],
            )
            for w in weeks
        ]
    except (json.JSONDecodeError, TypeError):
        raise HTTPException(status_code=500, detail="Stored plan data is corrupt.")


def _plan_to_response(plan: TrainingPlan) -> TrainingPlanResponse:
    return TrainingPlanResponse(
        planID       = plan.planID,
        clientID     = plan.clientID,
        title        = plan.title,
        goal         = plan.goal,
        level        = plan.level,
        weeks        = plan.weeks,
        status       = plan.status,
        completed_at = plan.completed_at,
        version      = plan.version,
        parent_plan_id = plan.parent_plan_id,
        plan         = _parse_plan_json(plan),
        raw_json     = plan.plan_json,
        created_at   = plan.created_at,
    )


# ── POST /training-plans/generate ────────────────────────────────────────────

@router.post(
    "/generate",
    response_model=TrainingPlanResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Generate a personalised AI training plan (equipment-aware)",
)
async def generate_training_plan(
    req: TrainingPlanRequest,
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
    summary="List all active training plans for the authenticated client",
)
async def list_training_plans(
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)
    result = await db.execute(
        select(TrainingPlan)
        .where(
            TrainingPlan.clientID  == client_id,
            TrainingPlan.is_active == True,
        )
        .order_by(TrainingPlan.created_at.desc())
    )
    return result.scalars().all()


# ── GET /training-plans/{id} ──────────────────────────────────────────────────

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
    plan      = await _get_owned_plan(plan_id, client_id, db)
    return _plan_to_response(plan)


# ── GET /training-plans/{id}/versions ────────────────────────────────────────

@router.get(
    "/{plan_id}/versions",
    response_model=list[TrainingPlanSummary],
    summary="Get all versions of a plan (edit history)",
)
async def get_plan_versions(
    plan_id: int,
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)
    plan      = await _get_owned_plan(plan_id, client_id, db)

    # The root plan is the top of the chain
    root_id = plan.parent_plan_id or plan_id

    # Get all versions: the root itself + anything whose parent chain leads there
    # Simple approach: fetch all plans for this client with matching parent or root id
    result = await db.execute(
        select(TrainingPlan)
        .where(
            TrainingPlan.clientID == client_id,
            (TrainingPlan.planID == root_id) |
            (TrainingPlan.parent_plan_id == root_id),
        )
        .order_by(TrainingPlan.version)
    )
    return result.scalars().all()


# ── PATCH /training-plans/{id} (Edit = new version) ──────────────────────────

@router.patch(
    "/{plan_id}",
    response_model=TrainingPlanResponse,
    summary="Edit a plan — creates a new version, never overwrites",
)
async def edit_training_plan(
    plan_id: int,
    req: TrainingPlanRequest,
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)
    old_plan  = await _get_owned_plan(plan_id, client_id, db)

    if old_plan.status == PlanStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Cannot edit a completed plan.")

    # Deactivate the old version
    old_plan.is_active = False

    # Generate new version via AI (passes old plan context to agent)
    try:
        new_plan = await gemini_agent.generate_plan(
            client_id   = client_id,
            req         = req,
            db          = db,
            parent_plan = old_plan,
        )
    except (ValueError, RuntimeError) as exc:
        raise HTTPException(status_code=502, detail=str(exc))

    await db.commit()
    await db.refresh(new_plan)
    return _plan_to_response(new_plan)


# ── POST /training-plans/{id}/duplicate ──────────────────────────────────────

@router.post(
    "/{plan_id}/duplicate",
    response_model=TrainingPlanSummary,
    status_code=status.HTTP_201_CREATED,
    summary="Clone an existing plan",
)
async def duplicate_plan(
    plan_id: int,
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)
    source    = await _get_owned_plan(plan_id, client_id, db)

    clone = TrainingPlan(
        clientID       = client_id,
        parent_plan_id = source.planID,
        version        = 1,
        is_active      = True,
        title          = f"{source.title} (Copy)",
        goal           = source.goal,
        level          = source.level,
        weeks          = source.weeks,
        gym_id         = source.gym_id,
        plan_json      = source.plan_json,
        status         = PlanStatus.IN_PROGRESS,
    )
    db.add(clone)
    await db.commit()
    await db.refresh(clone)
    return clone


# ── POST /training-plans/{id}/complete-day ───────────────────────────────────

@router.post(
    "/{plan_id}/complete-day",
    summary="Mark a day's workout as completed",
)
async def complete_day(
    plan_id: int,
    tracking_date: date,
    completed_exercises: int,
    total_exercises: int,
    duration_minutes: Optional[int] = None,
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)
    plan      = await _get_owned_plan(plan_id, client_id, db)

    if plan.status == PlanStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Plan is already completed.")

    completion = (completed_exercises / total_exercises * 100) if total_exercises > 0 else 0

    # Upsert tracking row
    res = await db.execute(
        select(TrainingPlanTracking).where(
            TrainingPlanTracking.clientID      == client_id,
            TrainingPlanTracking.planID        == plan_id,
            TrainingPlanTracking.tracking_date == tracking_date,
        )
    )
    tracking = res.scalar_one_or_none()

    if not tracking:
        # Derive week / day numbers from plan start date
        start_date   = plan.created_at.date()
        days_elapsed = (tracking_date - start_date).days
        week_num     = (days_elapsed // 7) + 1
        day_num      = (days_elapsed % 7) + 1

        tracking = TrainingPlanTracking(
            clientID              = client_id,
            planID                = plan_id,
            tracking_date         = tracking_date,
            week_number           = week_num,
            day_number            = day_num,
            planned_exercises     = total_exercises,
            completed_exercises   = completed_exercises,
            completion_percentage = completion,
            status                = WorkoutStatus.COMPLETED if completion >= 80 else WorkoutStatus.PARTIAL,
            duration_minutes      = duration_minutes,
            completed_at          = datetime.now(timezone.utc),
        )
        db.add(tracking)
    else:
        tracking.completed_exercises   = completed_exercises
        tracking.completion_percentage = completion
        tracking.status                = WorkoutStatus.COMPLETED if completion >= 80 else WorkoutStatus.PARTIAL
        tracking.duration_minutes      = duration_minutes
        tracking.completed_at          = datetime.now(timezone.utc)

    await db.commit()

    # Auto-complete plan if all workouts done
    await _check_auto_complete(client_id, plan, db)

    return {"message": "Day logged.", "completion_percentage": round(completion, 1)}


# ── PATCH /training-plans/{id}/complete ──────────────────────────────────────

@router.patch(
    "/{plan_id}/complete",
    response_model=TrainingPlanSummary,
    summary="Manually mark a training plan as completed",
)
async def complete_training_plan(
    plan_id: int,
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)
    plan      = await _get_owned_plan(plan_id, client_id, db)

    if plan.status == PlanStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Plan is already completed.")

    plan.status       = PlanStatus.COMPLETED
    plan.completed_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(plan)

    # Trigger achievement update
    await achievement_engine.on_plan_completed(client_id, db)

    return plan


# ── DELETE /training-plans/{id} ───────────────────────────────────────────────

@router.delete(
    "/{plan_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Deactivate (soft-delete) a training plan",
)
async def delete_training_plan(
    plan_id: int,
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)
    plan      = await _get_owned_plan(plan_id, client_id, db)
    plan.is_active = False
    await db.commit()


# ── GET /training-plans/{id}/pdf ─────────────────────────────────────────────

@router.get(
    "/{plan_id}/pdf",
    summary="Download training plan as PDF",
)
async def export_plan_pdf(
    plan_id: int,
    current_user = Depends(require_client),
    db: AsyncSession = Depends(get_session),
):
    client_id = await _get_client_id(current_user, db)
    plan      = await _get_owned_plan(plan_id, client_id, db)

    try:
        pdf_bytes = _generate_pdf(plan)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"PDF generation failed: {exc}")

    filename = f"training_plan_{plan.planID}.pdf"
    return StreamingResponse(
        BytesIO(pdf_bytes),
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


# ── Internal helpers ──────────────────────────────────────────────────────────

async def _check_auto_complete(
    client_id: int, plan: TrainingPlan, db: AsyncSession
) -> None:
    """Auto-complete the plan when all workouts are done."""
    from sqlalchemy import func as sqlfunc

    data            = json.loads(plan.plan_json)
    total_workouts  = sum(len(w.get("days", [])) for w in data.get("plan", []))

    res = await db.execute(
        select(sqlfunc.count(TrainingPlanTracking.trackingID))
        .where(
            TrainingPlanTracking.clientID == client_id,
            TrainingPlanTracking.planID   == plan.planID,
            TrainingPlanTracking.status   == WorkoutStatus.COMPLETED,
        )
    )
    completed = res.scalar() or 0

    if completed >= total_workouts and plan.status != PlanStatus.COMPLETED:
        plan.status       = PlanStatus.COMPLETED
        plan.completed_at = datetime.now(timezone.utc)
        await db.commit()
        await achievement_engine.on_plan_completed(client_id, db)


def _generate_pdf(plan: TrainingPlan) -> bytes:
    """
    Generate a PDF for the training plan using reportlab.
    Falls back gracefully if reportlab is not installed.
    """
    try:
        from reportlab.lib.pagesizes import A4
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.lib.units import cm
        from reportlab.platypus import (
            SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
        )
        from reportlab.lib import colors
    except ImportError:
        raise RuntimeError("reportlab is not installed. Run: pip install reportlab")

    buffer = BytesIO()
    doc    = SimpleDocTemplate(buffer, pagesize=A4,
                               leftMargin=2*cm, rightMargin=2*cm,
                               topMargin=2*cm, bottomMargin=2*cm)
    styles = getSampleStyleSheet()
    story  = []

    # ── Header ──
    story.append(Paragraph(plan.title, styles["Title"]))
    story.append(Spacer(1, 0.3*cm))
    meta = (
        f"Goal: {plan.goal} | Level: {plan.level or '—'} | "
        f"Duration: {plan.weeks or '?'} weeks | "
        f"Created: {plan.created_at.strftime('%Y-%m-%d')}"
    )
    story.append(Paragraph(meta, styles["Normal"]))
    story.append(Spacer(1, 0.5*cm))

    # ── Weeks & Days ──
    try:
        data  = json.loads(plan.plan_json)
        weeks = data.get("plan", [])
    except (json.JSONDecodeError, TypeError):
        weeks = []

    for week in weeks:
        week_title = f"Week {week.get('week', '?')}"
        if week.get("theme"):
            week_title += f" — {week['theme']}"
        story.append(Paragraph(week_title, styles["Heading2"]))
        story.append(Spacer(1, 0.2*cm))

        for day in week.get("days", []):
            story.append(Paragraph(
                f"<b>{day.get('day','')}</b> — {day.get('focus','')}",
                styles["Heading3"],
            ))
            exercises = day.get("exercises", [])
            if exercises:
                rows = [["Exercise", "Sets", "Reps", "Notes"]]
                for ex in exercises:
                    if isinstance(ex, dict):
                        rows.append([
                            ex.get("name", ""),
                            str(ex.get("sets", "")),
                            str(ex.get("reps", "")),
                            ex.get("notes", ""),
                        ])
                    else:
                        rows.append([str(ex), "", "", ""])

                tbl = Table(rows, colWidths=[6*cm, 2*cm, 2*cm, 7*cm])
                tbl.setStyle(TableStyle([
                    ("BACKGROUND", (0,0), (-1,0), colors.HexColor("#1a1a2e")),
                    ("TEXTCOLOR",  (0,0), (-1,0), colors.white),
                    ("FONTNAME",   (0,0), (-1,0), "Helvetica-Bold"),
                    ("ROWBACKGROUNDS", (0,1), (-1,-1), [colors.white, colors.HexColor("#f5f5f5")]),
                    ("GRID",       (0,0), (-1,-1), 0.4, colors.grey),
                    ("FONTSIZE",   (0,0), (-1,-1), 9),
                    ("PADDING",    (0,0), (-1,-1), 4),
                ]))
                story.append(tbl)

            if day.get("notes"):
                story.append(Paragraph(f"<i>Notes: {day['notes']}</i>", styles["Normal"]))
            story.append(Spacer(1, 0.3*cm))

        story.append(Spacer(1, 0.4*cm))

    doc.build(story)
    return buffer.getvalue()
