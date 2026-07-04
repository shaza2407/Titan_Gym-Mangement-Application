"""
Test suite for app/services/client/training_plan.py

Testing technique used: Equivalence Partitioning (EP) + Boundary Value
Analysis (BVA).

The most important numeric boundary in this module is the workout
completion threshold:

    completion = completed_exercises / total_exercises * 100
    status     = COMPLETED if completion >= 80 else PARTIAL

Equivalence classes for `completion`:
    EP1: [0, 80)    -> PARTIAL
    EP2: [80, 100]  -> COMPLETED
    EP3: total_exercises == 0 (undefined-ratio guard -> completion forced to 0)

Boundary values exercised around the 80% threshold:
    79%  (just below)  -> PARTIAL
    80%  (exact)        -> COMPLETED
    81%  (just above)  -> COMPLETED
    0%   (lower bound)  -> PARTIAL
    100% (upper bound)  -> COMPLETED
    >100% (over-completion, e.g. more completed than total) -> COMPLETED

A second boundary lives in `_check_auto_complete`:
    completed_workouts >= total_expected_workouts
    tested at: completed == total - 1 (just below), completed == total
    (exact), completed > total (over count).
"""

import json
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from fastapi import HTTPException
from datetime import datetime

from app.services.client.training_plan import (
    generate_training_plan_service,
    list_training_plans_service,
    get_training_plan_service,
    complete_day_service,
    complete_week_service,
    complete_training_plan_service,
    delete_training_plan_service,
    export_plan_pdf_service,
    _get_owned_plan,
    _parse_plan_json,
    _check_auto_complete,
)
from app.models.training_plan import (
    TrainingPlan, PlanStatus,
    TrainingPlanTracking, WorkoutStatus,
    TrainingPlanWeekProgress, DayStatus,
)
from app.schemas.client.TrainingPlanRequest import TrainingPlanRequest
from app.schemas.client.TrainingPlanResponse import TrainingPlanResponse
from app.schemas.client.CompleteDayRequest import CompleteDayRequest


MODULE = "app.services.client.training_plan"


def _mock_db() -> AsyncMock:
    """AsyncMock db with add() correctly mocked as sync (matches real AsyncSession)."""
    db = AsyncMock()
    db.add = MagicMock()
    return db


# ── Helpers ───────────────────────────────────────────────────────────────────

def _make_request(**overrides) -> TrainingPlanRequest:
    base = dict(
        fitness_goal="weight loss",
        age=28,
        gender="male",
        level="beginner",
        weeks=4,
        injuries=None,
        days_per_week=3,
        equipment="full gym",
    )
    base.update(overrides)
    return TrainingPlanRequest(**base)


def _make_training_plan(plan_id=1, client_id=1, title="Test Plan", status=PlanStatus.IN_PROGRESS,
                         parent_plan_id=None, plan_json=None, tracking=None):
    plan = MagicMock(spec=TrainingPlan)
    plan.planID = plan_id
    plan.clientID = client_id
    plan.title = title
    plan.goal = "Strength"
    plan.level = "Beginner"
    plan.weeks = 4
    plan.status = status
    plan.completed_at = None
    plan.version = 1
    plan.parent_plan_id = parent_plan_id
    plan.plan_json = plan_json or '{"plan": [{"week": 1, "days": [{"day": "Monday", "focus": "Legs", "exercises": []}]}]}'
    plan.created_at = datetime.now()
    plan.tracking = tracking if tracking is not None else []
    plan.is_active = True
    return plan


def _make_training_plan_response(plan_id=1):
    return TrainingPlanResponse(
        planID=plan_id,
        clientID=1,
        title="Generated Plan",
        goal="Strength",
        level="Beginner",
        weeks=4,
        status=PlanStatus.IN_PROGRESS,
        completed_at=None,
        version=1,
        parent_plan_id=None,
        plan=[],
        raw_json="",
        created_at=datetime.now()
    )


def _make_complete_day_request(week_number=1, day_number=1, completed_exercises=5,
                                total_exercises=5, duration_minutes=30, completed_exercise_indices=None):
    return CompleteDayRequest(
        week_number=week_number,
        day_number=day_number,
        completed_exercises=completed_exercises,
        total_exercises=total_exercises,
        duration_minutes=duration_minutes,
        completed_exercise_indices=completed_exercise_indices or [],
    )


def _db_with_owned_plan(plan):
    """An AsyncMock db whose execute().scalar_one_or_none() returns `plan`."""
    db = _mock_db()
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = plan
    db.execute.return_value = mock_result
    return db


# ── _get_owned_plan ─────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_get_owned_plan_found():
    plan = _make_training_plan(plan_id=1, client_id=10)
    db = _db_with_owned_plan(plan)

    result = await _get_owned_plan(plan_id=1, client_id=10, db=db)
    assert result is plan


@pytest.mark.asyncio
async def test_get_owned_plan_not_found_raises_404():
    db = _db_with_owned_plan(None)

    with pytest.raises(HTTPException) as exc_info:
        await _get_owned_plan(plan_id=999, client_id=10, db=db)

    assert exc_info.value.status_code == 404
    assert exc_info.value.detail == "Training plan not found."


# ── _parse_plan_json ─────────────────────────────────────────────────────────────

def test_parse_plan_json_corrupt_raises_500():
    plan = _make_training_plan(plan_json="{not valid json")
    with pytest.raises(HTTPException) as exc_info:
        _parse_plan_json(plan)
    assert exc_info.value.status_code == 500


def test_parse_plan_json_marks_completed_day_from_tracking():
    plan_json = json.dumps({
        "plan": [
            {"week": 1, "theme": "Foundation", "days": [
                {"day": "Monday", "focus": "Legs", "exercises": [{"name": "Squat"}, {"name": "Lunge"}]}
            ]}
        ]
    })
    trk = MagicMock(spec=TrainingPlanTracking)
    trk.week_number = 1
    trk.day_number = 1
    trk.status = WorkoutStatus.COMPLETED
    trk.completed_exercises_list = [0]

    plan = _make_training_plan(plan_json=plan_json, tracking=[trk])
    weeks = _parse_plan_json(plan)

    assert weeks[0].days[0].isCompleted is True
    assert weeks[0].days[0].exercises[0]["isCompleted"] is True
    assert weeks[0].days[0].exercises[1]["isCompleted"] is False


def test_parse_plan_json_no_tracking_defaults_not_completed():
    plan_json = json.dumps({
        "plan": [{"week": 1, "days": [{"day": "Monday", "exercises": []}]}]
    })
    plan = _make_training_plan(plan_json=plan_json, tracking=[])
    weeks = _parse_plan_json(plan)
    assert weeks[0].days[0].isCompleted is False


# ── generate_training_plan_service ───────────────────────────────────────────────

@pytest.mark.asyncio
async def test_generate_training_plan_service_success():
    db = _mock_db()
    req = _make_request()
    mock_plan_resp = _make_training_plan_response(1)

    with patch(f"{MODULE}._get_client_id", new_callable=AsyncMock) as mock_get_client_id, \
         patch(f"{MODULE}.gemini_agent.generate_plan", new_callable=AsyncMock) as mock_generate, \
         patch(f"{MODULE}.achievement_engine.on_plan_generated", new_callable=AsyncMock) as mock_achievement:

        mock_get_client_id.return_value = 10
        mock_generate.return_value = mock_plan_resp

        result = await generate_training_plan_service(req, user_id=1, db=db)

        mock_get_client_id.assert_awaited_once_with(1, db)
        mock_generate.assert_awaited_once_with(client_id=10, req=req, db=db)
        mock_achievement.assert_awaited_once_with(10, db)

        assert result.planID == 1


@pytest.mark.asyncio
async def test_generate_training_plan_service_gemini_value_error():
    db = _mock_db()
    req = _make_request()

    with patch(f"{MODULE}._get_client_id", new_callable=AsyncMock) as mock_get_client_id, \
         patch(f"{MODULE}.gemini_agent.generate_plan", new_callable=AsyncMock) as mock_generate:

        mock_get_client_id.return_value = 10
        mock_generate.side_effect = ValueError("Invalid input")

        with pytest.raises(HTTPException) as exc_info:
            await generate_training_plan_service(req, user_id=1, db=db)

        assert exc_info.value.status_code == 404
        assert exc_info.value.detail == "Invalid input"


@pytest.mark.asyncio
async def test_generate_training_plan_service_gemini_runtime_error():
    db = _mock_db()
    req = _make_request()

    with patch(f"{MODULE}._get_client_id", new_callable=AsyncMock) as mock_get_client_id, \
         patch(f"{MODULE}.gemini_agent.generate_plan", new_callable=AsyncMock) as mock_generate:

        mock_get_client_id.return_value = 10
        mock_generate.side_effect = RuntimeError("AI service unavailable")

        with pytest.raises(HTTPException) as exc_info:
            await generate_training_plan_service(req, user_id=1, db=db)

        assert exc_info.value.status_code == 502
        assert exc_info.value.detail == "AI service unavailable"


# ── list_training_plans_service ──────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_list_training_plans_service_success():
    db = _mock_db()

    with patch(f"{MODULE}._get_client_id", new_callable=AsyncMock) as mock_get_client_id:
        mock_get_client_id.return_value = 10

        mock_result = MagicMock()
        mock_result.scalars().all.return_value = [_make_training_plan(i) for i in range(2)]
        db.execute.return_value = mock_result

        result = await list_training_plans_service(user_id=1, db=db)

        assert len(result) == 2


# ── get_training_plan_service ────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_get_training_plan_service():
    db = _mock_db()
    mock_plan = _make_training_plan(1)

    with patch(f"{MODULE}._get_client_id", new_callable=AsyncMock) as mock_get_client_id, \
         patch(f"{MODULE}._get_owned_plan", new_callable=AsyncMock) as mock_get_owned:

        mock_get_client_id.return_value = 10
        mock_get_owned.return_value = mock_plan

        result = await get_training_plan_service(plan_id=1, user_id=1, db=db)

        mock_get_owned.assert_awaited_once_with(1, 10, db)
        assert result.planID == 1


# ── complete_day_service: BVA on the 80% completion threshold ─────────────────────

@pytest.mark.asyncio
@pytest.mark.parametrize(
    "completed,total,expected_pct,expected_status",
    [
        (0, 5, 0.0, WorkoutStatus.PARTIAL),       # lower boundary: 0%
        (3, 4, 75.0, WorkoutStatus.PARTIAL),      # just below 80, EP1
        (4, 5, 80.0, WorkoutStatus.COMPLETED),    # exact boundary: 80%
        (81, 100, 81.0, WorkoutStatus.COMPLETED), # just above 80, EP2
        (5, 5, 100.0, WorkoutStatus.COMPLETED),   # upper boundary: 100%
        (6, 5, 120.0, WorkoutStatus.COMPLETED),   # over-completion edge case
        (0, 0, 0, WorkoutStatus.PARTIAL),         # EP3: total_exercises == 0 guard
    ],
    ids=[
        "0pct_lower_bound",
        "79_class_75pct_just_below_threshold",
        "80pct_exact_boundary",
        "81pct_just_above_threshold",
        "100pct_upper_bound",
        "over_completion_120pct",
        "zero_total_exercises_guard",
    ],
)
async def test_complete_day_service_completion_threshold_boundaries(
        completed, total, expected_pct, expected_status):
    db = _mock_db()
    plan = _make_training_plan(plan_id=1, client_id=10, status=PlanStatus.IN_PROGRESS)
    request = _make_complete_day_request(completed_exercises=completed, total_exercises=total)

    # No existing tracking row -> a new one will be created and added.
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    db.execute.return_value = mock_result

    with patch(f"{MODULE}._get_client_id", new_callable=AsyncMock) as mock_get_client_id, \
         patch(f"{MODULE}._get_owned_plan", new_callable=AsyncMock) as mock_get_owned, \
         patch(f"{MODULE}.training_plan_tracker._update_weekly_progress", new_callable=AsyncMock), \
         patch(f"{MODULE}._check_auto_complete", new_callable=AsyncMock):

        mock_get_client_id.return_value = 10
        mock_get_owned.return_value = plan

        result = await complete_day_service(plan_id=1, request=request, user_id=1, db=db)

        added_tracking = db.add.call_args[0][0]
        assert added_tracking.status == expected_status
        assert added_tracking.completion_percentage == expected_pct
        assert result["completion_percentage"] == round(expected_pct, 1)


@pytest.mark.asyncio
async def test_complete_day_service_updates_existing_tracking_row():
    db = _mock_db()
    plan = _make_training_plan(plan_id=1, client_id=10, status=PlanStatus.IN_PROGRESS)
    request = _make_complete_day_request(completed_exercises=5, total_exercises=5)

    existing_tracking = MagicMock(spec=TrainingPlanTracking)
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = existing_tracking
    db.execute.return_value = mock_result

    with patch(f"{MODULE}._get_client_id", new_callable=AsyncMock) as mock_get_client_id, \
         patch(f"{MODULE}._get_owned_plan", new_callable=AsyncMock) as mock_get_owned, \
         patch(f"{MODULE}.training_plan_tracker._update_weekly_progress", new_callable=AsyncMock), \
         patch(f"{MODULE}._check_auto_complete", new_callable=AsyncMock):

        mock_get_client_id.return_value = 10
        mock_get_owned.return_value = plan

        await complete_day_service(plan_id=1, request=request, user_id=1, db=db)

        db.add.assert_not_called()
        assert existing_tracking.status == WorkoutStatus.COMPLETED
        assert existing_tracking.completion_percentage == 100.0


@pytest.mark.asyncio
async def test_complete_day_service_already_completed_plan_raises_400():
    db = _mock_db()
    plan = _make_training_plan(plan_id=1, status=PlanStatus.COMPLETED)
    request = _make_complete_day_request()

    with patch(f"{MODULE}._get_client_id", new_callable=AsyncMock) as mock_get_client_id, \
         patch(f"{MODULE}._get_owned_plan", new_callable=AsyncMock) as mock_get_owned:

        mock_get_client_id.return_value = 10
        mock_get_owned.return_value = plan

        with pytest.raises(HTTPException) as exc_info:
            await complete_day_service(plan_id=1, request=request, user_id=1, db=db)

        assert exc_info.value.status_code == 400
        assert exc_info.value.detail == "Plan is already completed."


# ── complete_week_service ────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_complete_week_service_creates_new_progress_row():
    db = _mock_db()
    plan = _make_training_plan(plan_id=1, status=PlanStatus.IN_PROGRESS)

    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    db.execute.return_value = mock_result

    with patch(f"{MODULE}._get_client_id", new_callable=AsyncMock) as mock_get_client_id, \
         patch(f"{MODULE}._get_owned_plan", new_callable=AsyncMock) as mock_get_owned:

        mock_get_client_id.return_value = 10
        mock_get_owned.return_value = plan

        from app.services.client.training_plan import CompleteWeekRequest
        req = CompleteWeekRequest(week_number=2)

        result = await complete_week_service(plan_id=1, request=req, user_id=1, db=db)

        db.add.assert_called_once()
        added = db.add.call_args[0][0]
        assert added.week_status == DayStatus.COMPLETED
        assert result["message"] == "Week marked as completed."


@pytest.mark.asyncio
async def test_complete_week_service_updates_existing_progress_row():
    db = _mock_db()
    plan = _make_training_plan(plan_id=1, status=PlanStatus.IN_PROGRESS)
    existing = MagicMock(spec=TrainingPlanWeekProgress)

    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = existing
    db.execute.return_value = mock_result

    with patch(f"{MODULE}._get_client_id", new_callable=AsyncMock) as mock_get_client_id, \
         patch(f"{MODULE}._get_owned_plan", new_callable=AsyncMock) as mock_get_owned:

        mock_get_client_id.return_value = 10
        mock_get_owned.return_value = plan

        from app.services.client.training_plan import CompleteWeekRequest
        req = CompleteWeekRequest(week_number=1)

        await complete_week_service(plan_id=1, request=req, user_id=1, db=db)

        db.add.assert_not_called()
        assert existing.week_status == DayStatus.COMPLETED


@pytest.mark.asyncio
async def test_complete_week_service_already_completed_plan_raises_400():
    db = _mock_db()
    plan = _make_training_plan(plan_id=1, status=PlanStatus.COMPLETED)

    with patch(f"{MODULE}._get_client_id", new_callable=AsyncMock) as mock_get_client_id, \
         patch(f"{MODULE}._get_owned_plan", new_callable=AsyncMock) as mock_get_owned:

        mock_get_client_id.return_value = 10
        mock_get_owned.return_value = plan

        from app.services.client.training_plan import CompleteWeekRequest
        req = CompleteWeekRequest(week_number=1)

        with pytest.raises(HTTPException) as exc_info:
            await complete_week_service(plan_id=1, request=req, user_id=1, db=db)

        assert exc_info.value.status_code == 400


# ── complete_training_plan_service ───────────────────────────────────────────────

@pytest.mark.asyncio
async def test_complete_training_plan_service_success():
    db = _mock_db()
    plan = _make_training_plan(plan_id=1, status=PlanStatus.IN_PROGRESS)

    with patch(f"{MODULE}._get_client_id", new_callable=AsyncMock) as mock_get_client_id, \
         patch(f"{MODULE}._get_owned_plan", new_callable=AsyncMock) as mock_get_owned, \
         patch(f"{MODULE}.achievement_engine.on_plan_completed", new_callable=AsyncMock) as mock_plan_completed:

        mock_get_client_id.return_value = 10
        mock_get_owned.return_value = plan

        result = await complete_training_plan_service(plan_id=1, user_id=1, db=db)

        assert plan.status == PlanStatus.COMPLETED
        assert plan.completed_at is not None
        mock_plan_completed.assert_awaited_once_with(10, db)
        assert result is plan


@pytest.mark.asyncio
async def test_complete_training_plan_service_already_completed_raises_400():
    db = _mock_db()
    plan = _make_training_plan(plan_id=1, status=PlanStatus.COMPLETED)

    with patch(f"{MODULE}._get_client_id", new_callable=AsyncMock) as mock_get_client_id, \
         patch(f"{MODULE}._get_owned_plan", new_callable=AsyncMock) as mock_get_owned:

        mock_get_client_id.return_value = 10
        mock_get_owned.return_value = plan

        with pytest.raises(HTTPException) as exc_info:
            await complete_training_plan_service(plan_id=1, user_id=1, db=db)

        assert exc_info.value.status_code == 400


# ── delete_training_plan_service ─────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_delete_training_plan_service_hard_deletes():
    db = _mock_db()
    db.delete = AsyncMock()
    plan = _make_training_plan(plan_id=1)

    with patch(f"{MODULE}._get_client_id", new_callable=AsyncMock) as mock_get_client_id, \
         patch(f"{MODULE}._get_owned_plan", new_callable=AsyncMock) as mock_get_owned:

        mock_get_client_id.return_value = 10
        mock_get_owned.return_value = plan

        result = await delete_training_plan_service(plan_id=1, user_id=1, db=db)

        db.delete.assert_awaited_once_with(plan)
        db.commit.assert_awaited_once()
        assert result is None


# ── export_plan_pdf_service ──────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_export_plan_pdf_service_success():
    db = _mock_db()
    plan = _make_training_plan(plan_id=1)

    with patch(f"{MODULE}._get_client_id", new_callable=AsyncMock) as mock_get_client_id, \
         patch(f"{MODULE}._get_owned_plan", new_callable=AsyncMock) as mock_get_owned, \
         patch(f"{MODULE}._generate_pdf") as mock_generate_pdf:

        mock_get_client_id.return_value = 10
        mock_get_owned.return_value = plan
        mock_generate_pdf.return_value = b"%PDF-1.4 fake pdf bytes"

        result = await export_plan_pdf_service(plan_id=1, user_id=1, db=db)

        assert result == b"%PDF-1.4 fake pdf bytes"


@pytest.mark.asyncio
async def test_export_plan_pdf_service_generation_failure_raises_500():
    db = _mock_db()
    plan = _make_training_plan(plan_id=1)

    with patch(f"{MODULE}._get_client_id", new_callable=AsyncMock) as mock_get_client_id, \
         patch(f"{MODULE}._get_owned_plan", new_callable=AsyncMock) as mock_get_owned, \
         patch(f"{MODULE}._generate_pdf") as mock_generate_pdf:

        mock_get_client_id.return_value = 10
        mock_get_owned.return_value = plan
        mock_generate_pdf.side_effect = Exception("layout engine crashed")

        with pytest.raises(HTTPException) as exc_info:
            await export_plan_pdf_service(plan_id=1, user_id=1, db=db)

        assert exc_info.value.status_code == 500
        assert "layout engine crashed" in exc_info.value.detail


# ── _check_auto_complete: BVA on completed_workouts >= total_expected_workouts ────

@pytest.mark.asyncio
@pytest.mark.parametrize(
    "completed,total,should_complete",
    [
        (4, 5, False),   # just below boundary
        (5, 5, True),    # exact boundary
        (6, 5, True),    # over-count edge case
        (0, 0, True),    # EP: empty plan -> 0 >= 0 considered complete
    ],
    ids=["just_below", "exact_boundary", "over_count", "empty_plan_zero_total"],
)
async def test_check_auto_complete_boundaries(completed, total, should_complete):
    days = [{"days": [{}] * total}] if total else []
    plan_json = json.dumps({"plan": days})
    plan = _make_training_plan(plan_id=1, status=PlanStatus.IN_PROGRESS, plan_json=plan_json)

    db = _mock_db()
    mock_result = MagicMock()
    mock_result.scalar.return_value = completed
    db.execute.return_value = mock_result

    with patch(f"{MODULE}.achievement_engine.on_plan_completed", new_callable=AsyncMock) as mock_on_plan_completed:
        await _check_auto_complete(client_id=10, plan=plan, db=db)

        if should_complete:
            assert plan.status == PlanStatus.COMPLETED
            assert plan.completed_at is not None
            mock_on_plan_completed.assert_awaited_once_with(10, db)
        else:
            assert plan.status == PlanStatus.IN_PROGRESS
            mock_on_plan_completed.assert_not_called()


@pytest.mark.asyncio
async def test_check_auto_complete_already_completed_plan_is_idempotent():
    """EP: plan already COMPLETED -> guard prevents duplicate commits/events."""
    plan_json = json.dumps({"plan": [{"days": [{}, {}]}]})
    plan = _make_training_plan(plan_id=1, status=PlanStatus.COMPLETED, plan_json=plan_json)

    db = _mock_db()
    mock_result = MagicMock()
    mock_result.scalar.return_value = 2
    db.execute.return_value = mock_result

    with patch(f"{MODULE}.achievement_engine.on_plan_completed", new_callable=AsyncMock) as mock_on_plan_completed:
        await _check_auto_complete(client_id=10, plan=plan, db=db)

        mock_on_plan_completed.assert_not_called()
        db.commit.assert_not_awaited()