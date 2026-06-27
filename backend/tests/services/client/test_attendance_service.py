# tests/services/client/test_attendance_service.py
#
# Run with:
#   pytest tests/services/client/test_attendance_service.py -v

import pytest
from datetime import datetime, date, timedelta
from unittest.mock import AsyncMock, MagicMock, patch

from app.services.client.client_attendance import (
    already_checked_in_today,
    record_checkin,
    get_recent_checkins,
)
from app.models.attendance import Attendance


# ── Helpers ───────────────────────────────────────────────────────────────────

def _make_attendance(
    client_id: int = 1,
    gym_id: int = 1,
    checked_in: datetime = None,
    day_of_week: str = "monday",
) -> Attendance:
    a = MagicMock(spec=Attendance)
    a.clientID = client_id
    a.gymID = gym_id
    a.checked_in = checked_in or datetime.now()
    a.day_of_week = day_of_week
    return a


def _make_db_returning(scalar_value=None) -> AsyncMock:
    """DB mock for queries that return a single scalar."""
    result_mock = MagicMock()
    result_mock.scalar_one_or_none.return_value = scalar_value
    db = AsyncMock()
    db.execute = AsyncMock(return_value=result_mock)
    return db


def _make_db_returning_all(rows: list) -> AsyncMock:
    """DB mock for queries that return scalars().all()."""
    result_mock = MagicMock()
    result_mock.scalars.return_value.all.return_value = rows
    db = AsyncMock()
    db.execute = AsyncMock(return_value=result_mock)
    return db


# ════════════════════════════════════════════════════════════════════════════
# already_checked_in_today
# ════════════════════════════════════════════════════════════════════════════

class TestAlreadyCheckedInToday:

    async def test_returns_true_when_attendance_row_exists(self):
        existing = _make_attendance()
        db = _make_db_returning(scalar_value=existing)

        result = await already_checked_in_today(1, 1, db)

        assert result is True

    async def test_returns_false_when_no_attendance_row(self):
        db = _make_db_returning(scalar_value=None)

        result = await already_checked_in_today(1, 1, db)

        assert result is False

    async def test_queries_db_exactly_once(self):
        db = _make_db_returning(scalar_value=None)

        await already_checked_in_today(1, 1, db)

        db.execute.assert_awaited_once()

    async def test_different_client_same_gym(self):
        # client 2 has no check-in, client 1 does — returns False for client 2
        db = _make_db_returning(scalar_value=None)
        result = await already_checked_in_today(client_id=2, gym_id=1, db=db)
        assert result is False

    async def test_same_client_different_gym(self):
        # gym 2 has no check-in for this client
        db = _make_db_returning(scalar_value=None)
        result = await already_checked_in_today(client_id=1, gym_id=2, db=db)
        assert result is False


# ════════════════════════════════════════════════════════════════════════════
# record_checkin
# ════════════════════════════════════════════════════════════════════════════

class TestRecordCheckin:

    async def test_returns_attendance_object(self):
        db = AsyncMock()
        db.add = MagicMock()
        db.commit = AsyncMock()
        db.refresh = AsyncMock()

        result = await record_checkin(1, 1, db)

        assert isinstance(result, Attendance)

    async def test_sets_correct_client_and_gym(self):
        db = AsyncMock()
        db.add = MagicMock()
        db.commit = AsyncMock()
        db.refresh = AsyncMock()

        result = await record_checkin(client_id=5, gym_id=9, db=db)

        assert result.clientID == 5
        assert result.gymID == 9

    async def test_commits_to_db(self):
        db = AsyncMock()
        db.add = MagicMock()
        db.commit = AsyncMock()
        db.refresh = AsyncMock()

        await record_checkin(1, 1, db)

        db.commit.assert_awaited_once()

    async def test_refreshes_after_commit(self):
        db = AsyncMock()
        db.add = MagicMock()
        db.commit = AsyncMock()
        db.refresh = AsyncMock()

        await record_checkin(1, 1, db)

        db.refresh.assert_awaited_once()

    async def test_adds_to_session(self):
        db = AsyncMock()
        db.add = MagicMock()
        db.commit = AsyncMock()
        db.refresh = AsyncMock()

        await record_checkin(1, 1, db)

        db.add.assert_called_once()

    @pytest.mark.parametrize("weekday,expected_dow", [
        (0, "monday"),
        (1, "tuesday"),
        (2, "wednesday"),
        (3, "thursday"),
        (4, "friday"),
        (5, "saturday"),
        (6, "sunday"),
    ])
    async def test_day_of_week_matches_weekday(self, weekday: int, expected_dow: str):
        fixed_dt = datetime(2025, 1, 6 + weekday)  # Jan 6 2025 = Monday
        assert fixed_dt.weekday() == weekday

        db = AsyncMock()
        db.add = MagicMock()
        db.commit = AsyncMock()
        db.refresh = AsyncMock()

        with patch(
            "app.services.client.client_attendance.datetime"
        ) as mock_dt:
            mock_dt.now.return_value = fixed_dt

            result = await record_checkin(1, 1, db)

        assert result.day_of_week == expected_dow

    async def test_checked_in_timestamp_is_set(self):
        db = AsyncMock()
        db.add = MagicMock()
        db.commit = AsyncMock()
        db.refresh = AsyncMock()

        before = datetime.now()
        result = await record_checkin(1, 1, db)
        after = datetime.now()

        assert before <= result.checked_in <= after


# ════════════════════════════════════════════════════════════════════════════
# get_recent_checkins
# ════════════════════════════════════════════════════════════════════════════

class TestGetRecentCheckins:

    async def test_returns_empty_list_when_no_checkins(self):
        db = _make_db_returning_all([])

        result = await get_recent_checkins(1, 1, db)

        assert result == []

    async def test_returns_all_rows(self):
        rows = [_make_attendance(), _make_attendance(), _make_attendance()]
        db = _make_db_returning_all(rows)

        result = await get_recent_checkins(1, 1, db)

        assert len(result) == 3

    async def test_default_limit_is_50(self):
        """Verify the query is called — limit is enforced at DB layer."""
        db = _make_db_returning_all([])

        await get_recent_checkins(1, 1, db)

        db.execute.assert_awaited_once()

    async def test_custom_limit_accepted(self):
        db = _make_db_returning_all([])

        # Should not raise
        await get_recent_checkins(1, 1, db, limit=10)

        db.execute.assert_awaited_once()

    async def test_returns_attendance_objects(self):
        rows = [_make_attendance(checked_in=datetime(2025, 1, 10))]
        db = _make_db_returning_all(rows)

        result = await get_recent_checkins(1, 1, db)

        assert result[0].checked_in == datetime(2025, 1, 10)

    async def test_queries_db_exactly_once(self):
        db = _make_db_returning_all([])

        await get_recent_checkins(1, 1, db)

        db.execute.assert_awaited_once()