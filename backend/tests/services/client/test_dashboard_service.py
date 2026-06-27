# tests/services/client/test_dashboard_service.py
#
# Run with:
#   pytest tests/services/client/test_dashboard_service.py -v
#
# Pure unit tests — no real DB, no server.
# The AsyncSession is fully mocked so tests run instantly.

import pytest
from datetime import date, timedelta
from unittest.mock import AsyncMock, MagicMock, patch

from app.services.client.client_dashboard import get_dashboard_stats


# ── Helpers ───────────────────────────────────────────────────────────────────

def _make_db(
    total_visits: int = 0,
    days_this_week: int = 0,
    streak_dates: list[date] = [],
    gym_name: str | None = "Titan Gym",
) -> AsyncMock:
    """
    Build a mock AsyncSession whose execute() returns controlled values
    for each of the 4 queries in get_dashboard_stats, in order:
      1. total_visits  (scalar)
      2. days_this_week (scalar)
      3. streak dates  (fetchall)
      4. gym lookup    (scalar_one_or_none)
    """
    db = AsyncMock()

    # Query 1 — total visits scalar
    total_mock = MagicMock()
    total_mock.scalar.return_value = total_visits

    # Query 2 — days this week scalar
    week_mock = MagicMock()
    week_mock.scalar.return_value = days_this_week

    # Query 3 — streak dates fetchall → list of (date,) tuples
    streak_mock = MagicMock()
    streak_mock.fetchall.return_value = [(d,) for d in streak_dates]

    # Query 4 — gym object
    gym_mock = MagicMock()
    if gym_name is not None:
        gym_obj = MagicMock()
        gym_obj.gymName = gym_name
        gym_mock.scalar_one_or_none.return_value = gym_obj
    else:
        gym_mock.scalar_one_or_none.return_value = None

    db.execute = AsyncMock(
        side_effect=[total_mock, week_mock, streak_mock, gym_mock]
    )
    return db


today = date.today()
yesterday = today - timedelta(days=1)
two_days_ago = today - timedelta(days=2)
three_days_ago = today - timedelta(days=3)
last_week = today - timedelta(days=8)


# ════════════════════════════════════════════════════════════════════════════
# TESTS
# ════════════════════════════════════════════════════════════════════════════

class TestTotalVisits:

    async def test_zero_visits(self):
        db = _make_db(total_visits=0)
        result = await get_dashboard_stats(1, 1, db)
        assert result["total_visits"] == 0

    async def test_single_visit(self):
        db = _make_db(total_visits=1, streak_dates=[today])
        result = await get_dashboard_stats(1, 1, db)
        assert result["total_visits"] == 1

    async def test_many_visits(self):
        db = _make_db(total_visits=42)
        result = await get_dashboard_stats(1, 1, db)
        assert result["total_visits"] == 42

    async def test_none_from_db_defaults_to_zero(self):
        # scalar() returns None when table is empty
        db = _make_db(total_visits=None)
        result = await get_dashboard_stats(1, 1, db)
        assert result["total_visits"] == 0


class TestDaysThisWeek:

    async def test_no_visits_this_week(self):
        db = _make_db(days_this_week=0)
        result = await get_dashboard_stats(1, 1, db)
        assert result["days_this_week"] == 0

    async def test_three_distinct_days_this_week(self):
        db = _make_db(days_this_week=3)
        result = await get_dashboard_stats(1, 1, db)
        assert result["days_this_week"] == 3

    async def test_max_seven_days(self):
        db = _make_db(days_this_week=7)
        result = await get_dashboard_stats(1, 1, db)
        assert result["days_this_week"] == 7

    async def test_none_from_db_defaults_to_zero(self):
        db = _make_db(days_this_week=None)
        result = await get_dashboard_stats(1, 1, db)
        assert result["days_this_week"] == 0


class TestStreak:

    async def test_no_visits_streak_is_zero(self):
        db = _make_db(streak_dates=[])
        result = await get_dashboard_stats(1, 1, db)
        assert result["current_streak"] == 0

    async def test_only_today_streak_is_one(self):
        db = _make_db(streak_dates=[today])
        result = await get_dashboard_stats(1, 1, db)
        assert result["current_streak"] == 1

    async def test_only_yesterday_streak_is_one(self):
        db = _make_db(streak_dates=[yesterday])
        result = await get_dashboard_stats(1, 1, db)
        assert result["current_streak"] == 1

    async def test_last_visit_two_days_ago_streak_is_zero(self):
        # Gap of 2+ days breaks the streak
        db = _make_db(streak_dates=[two_days_ago])
        result = await get_dashboard_stats(1, 1, db)
        assert result["current_streak"] == 0

    async def test_consecutive_today_and_yesterday(self):
        db = _make_db(streak_dates=[today, yesterday])
        result = await get_dashboard_stats(1, 1, db)
        assert result["current_streak"] == 2

    async def test_three_consecutive_days(self):
        db = _make_db(streak_dates=[today, yesterday, two_days_ago])
        result = await get_dashboard_stats(1, 1, db)
        assert result["current_streak"] == 3

    async def test_gap_in_middle_stops_streak(self):
        # today, yesterday, then skip two_days_ago → gap at three_days_ago
        db = _make_db(streak_dates=[today, yesterday, three_days_ago])
        result = await get_dashboard_stats(1, 1, db)
        assert result["current_streak"] == 2

    async def test_streak_starts_from_yesterday_not_today(self):
        # Visited yesterday and day before — still a valid streak
        db = _make_db(streak_dates=[yesterday, two_days_ago])
        result = await get_dashboard_stats(1, 1, db)
        assert result["current_streak"] == 2

    async def test_old_visits_no_recent_streak(self):
        # Last visit was over a week ago — streak is 0
        db = _make_db(streak_dates=[last_week, last_week - timedelta(days=1)])
        result = await get_dashboard_stats(1, 1, db)
        assert result["current_streak"] == 0

    async def test_long_streak(self):
        # 10 consecutive days ending today
        dates = [today - timedelta(days=i) for i in range(10)]
        db = _make_db(streak_dates=dates)
        result = await get_dashboard_stats(1, 1, db)
        assert result["current_streak"] == 10


class TestGymName:

    async def test_returns_gym_name_when_found(self):
        db = _make_db(gym_name="Iron Paradise")
        result = await get_dashboard_stats(1, 1, db)
        assert result["gym_name"] == "Iron Paradise"

    async def test_returns_none_when_gym_not_found(self):
        db = _make_db(gym_name=None)
        result = await get_dashboard_stats(1, 1, db)
        assert result["gym_name"] is None


class TestReturnShape:

    async def test_result_has_all_required_keys(self):
        db = _make_db(total_visits=5, days_this_week=2, streak_dates=[today])
        result = await get_dashboard_stats(1, 1, db)
        assert set(result.keys()) == {
            "total_visits",
            "days_this_week",
            "current_streak",
            "gym_name",
        }

    async def test_all_values_correct_together(self):
        dates = [today, yesterday, two_days_ago]
        db = _make_db(
            total_visits=30,
            days_this_week=4,
            streak_dates=dates,
            gym_name="Titan Gym",
        )
        result = await get_dashboard_stats(1, 1, db)
        assert result["total_visits"] == 30
        assert result["days_this_week"] == 4
        assert result["current_streak"] == 3
        assert result["gym_name"] == "Titan Gym"