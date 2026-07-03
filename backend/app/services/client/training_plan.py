import json
from datetime import date, datetime, timezone
from typing import Optional, List
from io import BytesIO

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models.client import Client
from app.models.training_plan import (
    TrainingPlan, PlanStatus,
    TrainingPlanTracking, WorkoutStatus,
    TrainingPlanWeekProgress, DayStatus,
)
from app.schemas.client.TrainingPlanRequest import TrainingPlanRequest
from app.schemas.client.TrainingPlanResponse import (
    TrainingPlanResponse, TrainingPlanSummary, WeekPlan, DayPlan,
)
from app.schemas.client.CompleteDayRequest import CompleteDayRequest
from pydantic import BaseModel

from app.services.client.gemini_agent import gemini_agent
from app.services.coach.achievement_engine import achievement_engine
from app.services.client.training_plan_tracker import training_plan_tracker
from app.services.client.client_utils import get_client_by_user_id

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    PageBreak,
    KeepTogether,
)
from reportlab.platypus.flowables import HRFlowable


class CompleteWeekRequest(BaseModel):
    week_number: int


async def _get_client_id(user_id: int, db: AsyncSession) -> int:
    client = await get_client_by_user_id(user_id, db, detail="Only clients can access training plans.")
    return client.clientID


async def _get_owned_plan(plan_id: int, client_id: int, db: AsyncSession) -> TrainingPlan:
    result = await db.execute(
        select(TrainingPlan).options(selectinload(TrainingPlan.tracking)).where(
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
        
        tracking_lookup = {}
        try:
            for t in getattr(plan, "tracking", []):
                if t.status == WorkoutStatus.COMPLETED or t.status == WorkoutStatus.PARTIAL:
                    tracking_lookup[(t.week_number, t.day_number)] = t
        except Exception:
            pass

        parsed_weeks = []
        for w in weeks:
            week_num = w.get("week", 0)
            parsed_days = []
            for d_idx, d in enumerate(w.get("days", [])):
                day_num = d_idx + 1
                trk = tracking_lookup.get((week_num, day_num))
                completed_indices = set(trk.completed_exercises_list or []) if trk else set()
                
                exercises = []
                for e_idx, e in enumerate(d.get("exercises", [])):
                    if isinstance(e, dict):
                        e["isCompleted"] = e_idx in completed_indices
                    exercises.append(e)

                parsed_days.append(
                    DayPlan(
                        day       = str(d.get("day", "")),
                        focus     = d.get("focus", ""),
                        exercises = exercises,
                        notes     = d.get("notes"),
                        isCompleted = (trk.status == WorkoutStatus.COMPLETED) if trk else False
                    )
                )
            parsed_weeks.append(
                WeekPlan(
                    week  = week_num,
                    theme = w.get("theme"),
                    days  = parsed_days,
                )
            )
        return parsed_weeks
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


async def generate_training_plan_service(req: TrainingPlanRequest, user_id: int, db: AsyncSession) -> TrainingPlanResponse:
    client_id = await _get_client_id(user_id, db)
    try:
        plan = await gemini_agent.generate_plan(client_id=client_id, req=req, db=db)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except RuntimeError as exc:
        raise HTTPException(status_code=502, detail=str(exc))

    await achievement_engine.on_plan_generated(client_id, db)
    return plan


async def list_training_plans_service(user_id: int, db: AsyncSession) -> list[TrainingPlanSummary]:
    client_id = await _get_client_id(user_id, db)
    result = await db.execute(
        select(TrainingPlan)
        .where(
            TrainingPlan.clientID  == client_id,
            TrainingPlan.is_active == True,
        )
        .order_by(TrainingPlan.created_at.desc())
    )
    return result.scalars().all()


async def get_training_plan_service(plan_id: int, user_id: int, db: AsyncSession) -> TrainingPlanResponse:
    client_id = await _get_client_id(user_id, db)
    plan      = await _get_owned_plan(plan_id, client_id, db)
    return _plan_to_response(plan)


async def complete_day_service(plan_id: int, request: CompleteDayRequest, user_id: int, db: AsyncSession) -> dict:
    week_number = request.week_number
    day_number = request.day_number
    completed_exercises = request.completed_exercises
    total_exercises = request.total_exercises
    duration_minutes = request.duration_minutes
    completed_exercise_indices = request.completed_exercise_indices
    client_id = await _get_client_id(user_id, db)
    plan      = await _get_owned_plan(plan_id, client_id, db)

    if plan.status == PlanStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Plan is already completed.")

    completion = (completed_exercises / total_exercises * 100) if total_exercises > 0 else 0

    res = await db.execute(
        select(TrainingPlanTracking).where(
            TrainingPlanTracking.clientID      == client_id,
            TrainingPlanTracking.planID        == plan_id,
            TrainingPlanTracking.week_number   == week_number,
            TrainingPlanTracking.day_number    == day_number,
        )
    )
    tracking = res.scalar_one_or_none()

    is_new_completed = False
    if not tracking:
        tracking = TrainingPlanTracking(
            clientID              = client_id,
            planID                = plan_id,
            tracking_date         = datetime.now(timezone.utc).date(),
            week_number           = week_number,
            day_number            = day_number,
            planned_exercises     = total_exercises,
            completed_exercises   = completed_exercises,
            completion_percentage = completion,
            completed_exercises_list = completed_exercise_indices,
            status                = WorkoutStatus.COMPLETED if completion >= 80 else WorkoutStatus.PARTIAL,
            duration_minutes      = duration_minutes,
            completed_at          = datetime.now(timezone.utc),
        )
        db.add(tracking)
        if tracking.status == WorkoutStatus.COMPLETED:
            is_new_completed = True
    else:
        was_completed = (tracking.status == WorkoutStatus.COMPLETED)
        tracking.tracking_date         = datetime.now(timezone.utc).date()
        tracking.completed_exercises   = completed_exercises
        tracking.completion_percentage = completion
        tracking.completed_exercises_list = completed_exercise_indices
        tracking.status                = WorkoutStatus.COMPLETED if completion >= 80 else WorkoutStatus.PARTIAL
        tracking.duration_minutes      = duration_minutes
        tracking.completed_at          = datetime.now(timezone.utc)
        if not was_completed and tracking.status == WorkoutStatus.COMPLETED:
            is_new_completed = True

    await db.commit()

    if is_new_completed:
        await achievement_engine.on_workout_logged(client_id, db)

    await training_plan_tracker._update_weekly_progress(client_id, plan_id, db)

    await _check_auto_complete(client_id, plan, db)

    return {"message": "Day logged.", "completion_percentage": round(completion, 1)}


async def complete_week_service(plan_id: int, request: CompleteWeekRequest, user_id: int, db: AsyncSession) -> dict:
    week_number = request.week_number
    client_id = await _get_client_id(user_id, db)
    plan      = await _get_owned_plan(plan_id, client_id, db)

    if plan.status == PlanStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Plan is already completed.")

    res = await db.execute(
        select(TrainingPlanWeekProgress).where(
            TrainingPlanWeekProgress.clientID    == client_id,
            TrainingPlanWeekProgress.planID      == plan_id,
            TrainingPlanWeekProgress.week_number == week_number,
        )
    )
    week_progress = res.scalar_one_or_none()

    if not week_progress:
        week_progress = TrainingPlanWeekProgress(
            clientID        = client_id,
            planID          = plan_id,
            week_number     = week_number,
            week_end_date   = datetime.now(timezone.utc).date(),
            week_status     = DayStatus.COMPLETED,
        )
        db.add(week_progress)
    else:
        week_progress.week_end_date = datetime.now(timezone.utc).date()
        week_progress.week_status   = DayStatus.COMPLETED

    await db.commit()

    return {"message": "Week marked as completed."}


async def complete_training_plan_service(plan_id: int, user_id: int, db: AsyncSession) -> TrainingPlanSummary:
    client_id = await _get_client_id(user_id, db)
    plan      = await _get_owned_plan(plan_id, client_id, db)

    if plan.status == PlanStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Plan is already completed.")

    plan.status       = PlanStatus.COMPLETED
    plan.completed_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(plan)

    await achievement_engine.on_plan_completed(client_id, db)

    return plan


async def delete_training_plan_service(plan_id: int, user_id: int, db: AsyncSession) -> None:
    client_id = await _get_client_id(user_id, db)
    plan      = await _get_owned_plan(plan_id, client_id, db)
    await db.delete(plan)
    await db.commit()


async def export_plan_pdf_service(plan_id: int, user_id: int, db: AsyncSession) -> bytes:
    client_id = await _get_client_id(user_id, db)
    plan      = await _get_owned_plan(plan_id, client_id, db)

    try:
        pdf_bytes = _generate_pdf(plan)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"PDF generation failed: {exc}")

    return pdf_bytes


async def _check_auto_complete(client_id: int, plan: TrainingPlan, db: AsyncSession) -> None:
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
    Generate a clean and professional PDF for a training plan.
    """

    try:
        from reportlab.pdfbase.ttfonts import TTFont
        from reportlab.pdfbase import pdfmetrics
    except Exception:
        pass

    buffer = BytesIO()

    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        leftMargin=1.5 * cm,
        rightMargin=1.5 * cm,
        topMargin=1.5 * cm,
        bottomMargin=1.5 * cm,
    )

    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        "CustomTitle",
        parent=styles["Title"],
        fontName="Helvetica-Bold",
        fontSize=24,
        leading=30,
        textColor=colors.HexColor("#1a1a2e"),
        spaceAfter=14,
    )

    section_style = ParagraphStyle(
        "SectionStyle",
        parent=styles["Heading2"],
        fontName="Helvetica-Bold",
        fontSize=18,
        leading=22,
        textColor=colors.HexColor("#16213e"),
        spaceBefore=16,
        spaceAfter=10,
    )

    workout_style = ParagraphStyle(
        "WorkoutStyle",
        parent=styles["Heading3"],
        fontName="Helvetica-Bold",
        fontSize=13,
        leading=16,
        textColor=colors.HexColor("#0f3460"),
        spaceBefore=12,
        spaceAfter=8,
    )

    normal_style = ParagraphStyle(
        "NormalStyle",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=10,
        leading=14,
    )

    small_style = ParagraphStyle(
        "SmallStyle",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=9,
        leading=12,
        textColor=colors.HexColor("#555555"),
    )

    story = []

    story.append(Paragraph(plan.title, title_style))

    meta = f"""
    <b>Goal:</b> {plan.goal}<br/>
    <b>Level:</b> {plan.level or 'N/A'}<br/>
    <b>Duration:</b> {plan.weeks or '?'} weeks<br/>
    <b>Created:</b> {plan.created_at.strftime('%Y-%m-%d')}
    """

    story.append(Paragraph(meta, normal_style))
    story.append(Spacer(1, 0.4 * cm))

    story.append(
        HRFlowable(
            width="100%",
            thickness=1,
            color=colors.HexColor("#1a1a2e"),
        )
    )

    story.append(Spacer(1, 0.4 * cm))

    try:
        data = json.loads(plan.plan_json)
        weeks = data.get("plan", [])
    except Exception:
        weeks = []

    for week_index, week in enumerate(weeks, start=1):

        week_number = week.get("week", week_index)

        week_title = f"Week {week_number}"

        if week.get("theme"):
            week_title += f" — {week['theme']}"

        story.append(Paragraph(week_title, section_style))
        story.append(Spacer(1, 0.15 * cm))

        days = week.get("days", [])

        for day_index, day in enumerate(days, start=1):

            day_name = day.get("day", f"Workout Day {day_index}")
            focus = day.get("focus", "")

            if focus:
                heading = f"{day_name} — {focus}"
            else:
                heading = day_name

            story.append(Paragraph(heading, workout_style))

            exercises = day.get("exercises", [])

            if exercises:

                rows = [
                    [
                        Paragraph("<b>Exercise</b>", small_style),
                        Paragraph("<b>Sets</b>", small_style),
                        Paragraph("<b>Reps</b>", small_style),
                        Paragraph("<b>Notes</b>", small_style),
                    ]
                ]

                for ex in exercises:

                    if isinstance(ex, dict):

                        name = Paragraph(
                            str(ex.get("name", "")),
                            small_style,
                        )

                        sets = Paragraph(
                            str(ex.get("sets", "")),
                            small_style,
                        )

                        reps = Paragraph(
                            str(ex.get("reps", "")),
                            small_style,
                        )

                        notes = Paragraph(
                            str(ex.get("notes", "")),
                            small_style,
                        )

                        rows.append([name, sets, reps, notes])

                    else:

                        rows.append(
                            [
                                Paragraph(str(ex), small_style),
                                "",
                                "",
                                "",
                            ]
                        )

                table = Table(
                    rows,
                    repeatRows=1,
                    colWidths=[
                        5.5 * cm,
                        2 * cm,
                        2.5 * cm,
                        6.5 * cm,
                    ],
                )

                table.setStyle(
                    TableStyle(
                        [
                            (
                                "BACKGROUND",
                                (0, 0),
                                (-1, 0),
                                colors.HexColor("#1a1a2e"),
                            ),
                            (
                                "TEXTCOLOR",
                                (0, 0),
                                (-1, 0),
                                colors.white,
                            ),
                            (
                                "FONTNAME",
                                (0, 0),
                                (-1, 0),
                                "Helvetica-Bold",
                            ),
                            (
                                "FONTSIZE",
                                (0, 0),
                                (-1, 0),
                                10,
                            ),
                            (
                                "BACKGROUND",
                                (0, 1),
                                (-1, -1),
                                colors.white,
                            ),
                            (
                                "ROWBACKGROUNDS",
                                (0, 1),
                                (-1, -1),
                                [
                                    colors.white,
                                    colors.HexColor("#f7f7f7"),
                                ],
                            ),
                            (
                                "GRID",
                                (0, 0),
                                (-1, -1),
                                0.5,
                                colors.HexColor("#cccccc"),
                            ),
                            (
                                "VALIGN",
                                (0, 0),
                                (-1, -1),
                                "TOP",
                            ),
                            (
                                "LEFTPADDING",
                                (0, 0),
                                (-1, -1),
                                6,
                            ),
                            (
                                "RIGHTPADDING",
                                (0, 0),
                                (-1, -1),
                                6,
                            ),
                            (
                                "TOPPADDING",
                                (0, 0),
                                (-1, -1),
                                6,
                            ),
                            (
                                "BOTTOMPADDING",
                                (0, 0),
                                (-1, -1),
                                6,
                            ),
                        ]
                    )
                )

                story.append(KeepTogether(table))

            if day.get("notes"):
                story.append(
                    Spacer(1, 0.1 * cm)
                )

                story.append(
                    Paragraph(
                        f"<i>Notes:</i> {day['notes']}",
                        normal_style,
                    )
                )

            story.append(Spacer(1, 0.35 * cm))

        story.append(Spacer(1, 0.5 * cm))

    doc.build(story)

    pdf = buffer.getvalue()
    buffer.close()

    return pdf
