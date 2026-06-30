"""
Test suite for app/services/client/training_plan_tracker.py (TrainingPlanTracker)

Testing technique used: Equivalence Partitioning (EP) + Boundary Value
Analysis (BVA).

NOTE: the previous version of this test file referenced method names
(`check_plan_completion`) and an enum member (`WorkoutStatus.MISSED`) that do
not exist on the current source module (the real private methods are
`_check_plan_completion` / `_update_weekly_progress`, and WorkoutStatus only
has COMPLETED / PARTIAL / SKIPPED / PLANNED). Those mismatches are fixed here
so the suite actually exercises the real code paths.

Boundary #1 - completion percentage threshold (mark_workout_completed)
    completion = completed_exercises / total_exercises * 100
    status     = COMPLETED if completion >= 80 else PARTIAL
    EP1 [0,80) -> PARTIAL, EP2 [80,100] -> COMPLETED, EP3 total==0 guard.
    Boundaries tested: 0%, 79%, 80% (exact), 81%, 100%, total_exercises=0.

Boundary #2 - plan completion threshold (_check_plan_completion)
    completed_workouts >= total_expected_workouts
    Boundaries tested: total-1 (just below), total (exact), total+1 (over).

Boundary #3 - week rollover (_calculate_week_and_day)
    days_since_start // 7 (week) and % 7 (day)
    Boundaries tested: day 0 (week1/day1), day 6 (week1/day7, last day of
    week 1), day 7 (week2/day1, first day of week 2 - rollover boundary).

Boundary #4 - weekly aggregate completeness (_update_weekly_progress)
    completed == total -> COMPLETED, completed < total -> IN_PROGRESS.
"""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from datetime import date, datetime

from app.services.client.training_plan_tracker import TrainingPlanTracker
from app.models.training_plan import (
    TrainingPlan, TrainingPlanTracking, WorkoutStatus,
    TrainingPlanWeekProgress, DayStatus,
)

MODULE = "app.services.client.training_plan_tracker"


# ── Helpers ───────────────────────────────────────────────────────────────────

def _make_training_plan(plan_id=1, client_id=1, plan_json=None, created_at=None):
    plan = MagicMock(spec=TrainingPlan)
    plan.planID = plan_id
    plan.clientID = client_id
    plan.plan_json = plan_json or '{"plan": [{"week": 1, "days": [{"day": "Monday", "focus": "Legs", "exercises": []}]}]}'
    plan.created_at = created_at or datetime(2023, 1, 1)
    plan.status = None
    return plan


def _make_tracking(tracking_id=1, status=WorkoutStatus.PLANNED, week_number=1, tracking_date=None):
    tracking = MagicMock(spec=TrainingPlanTracking)
    tracking.trackingID = tracking_id
    tracking.completed_exercises_list = []
    tracking.status = status
    tracking.week_number = week_number
    tracking.tracking_date = tracking_date or date(2023, 1, 1)
    return tracking


def _result_with_scalar_one_or_none(value):
    r = MagicMock()
    r.scalar_one_or_none.return_value = value
    return r


def _result_with_scalar_one(value):
    r = MagicMock()
    r.scalar_one.return_value = value
    return r


def _result_with_scalar(value):
    r = MagicMock()
    r.scalar.return_value = value
    return r


def _result_with_scalars_all(values):
    r = MagicMock()
    r.scalars.return_value.all.return_value = values
    return r


# ── mark_workout_completed: BVA on the 80% completion threshold ───────────────

@pytest.mark.asyncio
@pytest.mark.parametrize(
    "completed,total,expected_pct,expected_status",
    [
        (0, 5, 0.0, WorkoutStatus.PARTIAL),        # lower boundary 0%
        (79, 100, 79.0, WorkoutStatus.PARTIAL),    # just below threshold
        (4, 5, 80.0, WorkoutStatus.COMPLETED),     # exact boundary 80%
        (81, 100, 81.0, WorkoutStatus.COMPLETED),  # just above threshold
        (5, 5, 100.0, WorkoutStatus.COMPLETED),    # upper boundary 100%
        (0, 0, 0, WorkoutStatus.PARTIAL),          # EP3: zero-total guard
    ],
    ids=[
        "0pct_lower_bound",
        "79pct_just_below_threshold",
        "80pct_exact_boundary",
        "81pct_just_above_threshold",
        "100pct_upper_bound",
        "zero_total_exercises_guard",
    ],
)
async def test_mark_workout_completed_existing_tracking_threshold_boundaries(
        completed, total, expected_pct, expected_status):
    tracker = TrainingPlanTracker()
    db = AsyncMock()

    mock_tracking = _make_tracking(1)
    db.execute.return_value = _result_with_scalar_one_or_none(mock_tracking)

    with patch(f"{MODULE}.achievement_engine.on_workout_logged", new_callable=AsyncMock) as mock_achievement, \
         patch.object(TrainingPlanTracker, "_check_plan_completion", new_callable=AsyncMock) as mock_check_completion, \
         patch.object(TrainingPlanTracker, "_update_weekly_progress", new_callable=AsyncMock) as mock_update_weekly:

        await tracker.mark_workout_completed(
            client_id=1,
            plan_id=1,
            tracking_date=date(2023, 1, 1),
            completed_exercises=completed,
            total_exercises=total,
            duration_minutes=60,
            db=db,
        )

        assert mock_tracking.status == expected_status
        assert mock_tracking.completion_percentage == expected_pct

        db.commit.assert_awaited_once()
        mock_check_completion.assert_awaited_once_with(1, 1, db)
        mock_update_weekly.assert_awaited_once_with(1, 1, db)
        mock_achievement.assert_awaited_once_with(1, db)


@pytest.mark.asyncio
async def test_mark_workout_completed_new_tracking_record_created():
    tracker = TrainingPlanTracker()
    db = AsyncMock()
    mock_plan = _make_training_plan(plan_id=1, created_at=datetime(2023, 1, 1))

    # 1st execute -> no existing tracking row, 2nd execute -> the plan itself
    db.execute.side_effect = [
        _result_with_scalar_one_or_none(None),
        _result_with_scalar_one(mock_plan),
    ]

    with patch(f"{MODULE}.achievement_engine.on_workout_logged", new_callable=AsyncMock), \
         patch.object(TrainingPlanTracker, "_check_plan_completion", new_callable=AsyncMock), \
         patch.object(TrainingPlanTracker, "_update_weekly_progress", new_callable=AsyncMock):

        await tracker.mark_workout_completed(
            client_id=1,
            plan_id=1,
            tracking_date=date(2023, 1, 1),
            completed_exercises=5,
            total_exercises=5,
            duration_minutes=60,
            db=db,
        )

        db.add.assert_called_once()
        added_tracking = db.add.call_args[0][0]
        assert isinstance(added_tracking, TrainingPlanTracking)
        assert added_tracking.status == WorkoutStatus.COMPLETED
        assert added_tracking.completion_percentage == 100.0
        # day 0 since plan start -> week 1 / day 1 (boundary case, see
        # _calculate_week_and_day tests below)
        assert added_tracking.week_number == 1
        assert added_tracking.day_number == 1

        db.commit.assert_awaited_once()


# ── _check_plan_completion: BVA on completed_workouts >= total_expected ───────

@pytest.mark.asyncio
@pytest.mark.parametrize(
    "completed,total,should_complete",
    [
        (4, 5, False),  # just below boundary
        (5, 5, True),   # exact boundary
        (6, 5, True),   # over-count edge case
    ],
    ids=["just_below_boundary", "exact_boundary", "over_count"],
)
async def test_check_plan_completion_boundaries(completed, total, should_complete):
    tracker = TrainingPlanTracker()
    db = AsyncMock()

    import json as _json
    days = [{} for _ in range(total)]
    plan_json = _json.dumps({"plan": [{"days": days}]})

    plan = _make_training_plan(plan_id=1, plan_json=plan_json)
    plan.status = None  # not yet completed

    db.execute.side_effect = [
        _result_with_scalar_one(plan),
        _result_with_scalar(completed),
    ]

    with patch(f"{MODULE}.achievement_engine.on_plan_completed", new_callable=AsyncMock) as mock_on_completed:
        await tracker._check_plan_completion(client_id=1, plan_id=1, db=db)

        if should_complete:
            from app.models.training_plan import PlanStatus
            assert plan.status == PlanStatus.COMPLETED
            assert plan.completed_at is not None
            mock_on_completed.assert_awaited_once_with(1, db)
            db.commit.assert_awaited_once()
        else:
            mock_on_completed.assert_not_called()


@pytest.mark.asyncio
async def test_check_plan_completion_already_completed_is_idempotent():
    from app.models.training_plan import PlanStatus
    tracker = TrainingPlanTracker()
    db = AsyncMock()

    import json as _json
    plan_json = _json.dumps({"plan": [{"days": [{}, {}]}]})
    plan = _make_training_plan(plan_id=1, plan_json=plan_json)
    plan.status = PlanStatus.COMPLETED

    db.execute.side_effect = [
        _result_with_scalar_one(plan),
        _result_with_scalar(2),
    ]

    with patch(f"{MODULE}.achievement_engine.on_plan_completed", new_callable=AsyncMock) as mock_on_completed:
        await tracker._check_plan_completion(client_id=1, plan_id=1, db=db)
        mock_on_completed.assert_not_called()
        db.commit.assert_not_awaited()


# ── _update_weekly_progress ─────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_update_weekly_progress_creates_new_week_row_when_all_completed():
    tracker = TrainingPlanTracker()
    db = AsyncMock()

    trackings = [
        _make_tracking(1, status=WorkoutStatus.COMPLETED, week_number=1, tracking_date=date(2023, 1, 1)),
        _make_tracking(2, status=WorkoutStatus.COMPLETED, week_number=1, tracking_date=date(2023, 1, 2)),
    ]

    db.execute.side_effect = [
        _result_with_scalars_all(trackings),
        _result_with_scalar_one_or_none(None),
    ]

    await tracker._update_weekly_progress(client_id=1, plan_id=1, db=db)

    db.add.assert_called_once()
    added = db.add.call_args[0][0]
    assert added.total_days == 2
    assert added.completed_days == 2
    assert added.week_status == DayStatus.COMPLETED
    assert added.average_completion == 100.0
    db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_update_weekly_progress_partial_week_marked_in_progress():
    """EP: completed < total -> IN_PROGRESS (boundary just below "all done")."""
    tracker = TrainingPlanTracker()
    db = AsyncMock()

    trackings = [
        _make_tracking(1, status=WorkoutStatus.COMPLETED, week_number=1, tracking_date=date(2023, 1, 1)),
        _make_tracking(2, status=WorkoutStatus.PLANNED, week_number=1, tracking_date=date(2023, 1, 2)),
        _make_tracking(3, status=WorkoutStatus.SKIPPED, week_number=1, tracking_date=date(2023, 1, 3)),
    ]
    existing_week = MagicMock(spec=TrainingPlanWeekProgress)

    db.execute.side_effect = [
        _result_with_scalars_all(trackings),
        _result_with_scalar_one_or_none(existing_week),
    ]

    await tracker._update_weekly_progress(client_id=1, plan_id=1, db=db)

    db.add.assert_not_called()
    assert existing_week.total_days == 3
    assert existing_week.completed_days == 1
    assert existing_week.skipped_days == 1
    assert existing_week.week_status == DayStatus.IN_PROGRESS


@pytest.mark.asyncio
async def test_update_weekly_progress_no_trackings_is_a_noop():
    """EP: zero trackings -> no week groups -> commit still called, nothing added."""
    tracker = TrainingPlanTracker()
    db = AsyncMock()
    db.execute.return_value = _result_with_scalars_all([])

    await tracker._update_weekly_progress(client_id=1, plan_id=1, db=db)

    db.add.assert_not_called()
    db.commit.assert_awaited_once()


# ── _calculate_week_and_day: BVA on the week-rollover boundary ────────────────

@pytest.mark.asyncio
@pytest.mark.parametrize(
    "days_since_start,expected_week,expected_day",
    [
        (0, 1, 1),   # first day of the plan
        (6, 1, 7),   # last day of week 1
        (7, 2, 1),   # rollover boundary: first day of week 2
        (13, 2, 7),  # last day of week 2
        (14, 3, 1),  # second rollover boundary
    ],
    ids=["day0_week1day1", "day6_week1day7", "day7_rollover_week2day1",
         "day13_week2day7", "day14_rollover_week3day1"],
)
async def test_calculate_week_and_day_boundaries(days_since_start, expected_week, expected_day):
    tracker = TrainingPlanTracker()
    plan_start = date(2023, 1, 1)
    tracking_date = date.fromordinal(plan_start.toordinal() + days_since_start)

    week, day = tracker._calculate_week_and_day({}, tracking_date, plan_start)

    assert week == expected_week
    assert day == expected_day


# ── _count_total_workouts ────────────────────────────────────────────────────────

@pytest.mark.asyncio
@pytest.mark.parametrize(
    "plan_data,expected_total",
    [
        ({}, 0),                                                            # empty dict, missing 'plan' key
        ({"plan": []}, 0),                                                  # empty plan, lower boundary
        ({"plan": [{"days": []}]}, 0),                                      # week with zero days
        ({"plan": [{"days": [{}]}]}, 1),                                    # single workout
        ({"plan": [{"days": [{}, {}]}, {"days": [{}, {}, {}]}]}, 5),        # multi-week summation
    ],
    ids=["empty_dict_missing_plan", "empty_plan", "week_with_zero_days", "single_workout", "multi_week_summation"],
)
async def test_count_total_workouts_boundaries(plan_data, expected_total):
    tracker = TrainingPlanTracker()
    assert tracker._count_total_workouts(plan_data) == expected_total


# ── get_plan_progress ─────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_get_plan_progress_zero_trackings_avoids_division_by_zero():
    tracker = TrainingPlanTracker()
    db = AsyncMock()
    plan = _make_training_plan(plan_id=1)
    plan.title = "Empty Plan"

    db.execute.side_effect = [
        _result_with_scalar_one(plan),
        _result_with_scalars_all([]),
        _result_with_scalars_all([]),
    ]

    result = await tracker.get_plan_progress(client_id=1, plan_id=1, db=db)

    assert result["total_workouts"] == 0
    assert result["completion_percentage"] == 0
    assert result["weeks"] == []
    assert result["daily_tracking"] == []


@pytest.mark.asyncio
async def test_get_plan_progress_aggregates_mixed_statuses():
    tracker = TrainingPlanTracker()
    db = AsyncMock()
    plan = _make_training_plan(plan_id=1)
    plan.title = "Mixed Plan"

    trackings = [
        _make_tracking(1, status=WorkoutStatus.COMPLETED),
        _make_tracking(2, status=WorkoutStatus.PARTIAL),
        _make_tracking(3, status=WorkoutStatus.SKIPPED),
    ]
    for t in trackings:
        t.completed_exercises = 5
        t.planned_exercises = 5
        t.completion_percentage = 100.0

    week = MagicMock(spec=TrainingPlanWeekProgress)
    week.week_number = 1
    week.completed_days = 1
    week.total_days = 3
    week.week_status = DayStatus.IN_PROGRESS

    db.execute.side_effect = [
        _result_with_scalar_one(plan),
        _result_with_scalars_all(trackings),
        _result_with_scalars_all([week]),
    ]

    result = await tracker.get_plan_progress(client_id=1, plan_id=1, db=db)

    assert result["total_workouts"] == 3
    assert result["completed_workouts"] == 1
    assert result["partial_workouts"] == 1
    assert result["skipped_workouts"] == 1
    assert result["completion_percentage"] == pytest.approx(33.333, rel=1e-3)
    assert result["weeks"][0]["percentage"] == pytest.approx(33.333, rel=1e-3)
