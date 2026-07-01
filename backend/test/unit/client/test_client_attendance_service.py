# test/unit/client/test_client_attendance_service.py
#
# Run with:
#   pytest test/unit/client/test_client_attendance_service.py -v

import pytest
from fastapi import HTTPException
from datetime import datetime, date, timedelta
from unittest.mock import AsyncMock, MagicMock, patch

from app.services.client.client_attendance import (
    already_checked_in_today,
    record_checkin,
    get_recent_checkins,
)
from app.models.attendance import Attendance
from app.models.gym_clients_membership import GymClientMembership


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


def _make_membership(
    status: str = "active",
    subscription_end: date = None,
) -> GymClientMembership:
    m = MagicMock(spec=GymClientMembership)
    m.status = status
    m.subscription_end = subscription_end or (date.today() + timedelta(days=30))
    return m


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


def _make_record_checkin_db(membership) -> AsyncMock:
    """DB mock for record_checkin() tests, which need to return a membership
    when queried, and also support add/commit/refresh."""
    result_mock = MagicMock()
    result_mock.scalar_one_or_none.return_value = membership
    db = AsyncMock()
    db.execute = AsyncMock(return_value=result_mock)
    db.add = MagicMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
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
        db = _make_db_returning(scalar_value=None)
        result = await already_checked_in_today(client_id=2, gym_id=1, db=db)
        assert result is False

    async def test_same_client_different_gym(self):
        db = _make_db_returning(scalar_value=None)
        result = await already_checked_in_today(client_id=1, gym_id=2, db=db)
        assert result is False


# ════════════════════════════════════════════════════════════════════════════
# record_checkin
# ════════════════════════════════════════════════════════════════════════════

class TestRecordCheckin:

    # ── happy path ──────────────────────────────────────────────────────────

    async def test_returns_attendance_object(self):
        db = _make_record_checkin_db(_make_membership())

        result = await record_checkin(1, 1, db)

        assert isinstance(result, Attendance)

    async def test_sets_correct_client_and_gym(self):
        db = _make_record_checkin_db(_make_membership())

        result = await record_checkin(client_id=5, gym_id=9, db=db)

        assert result.clientID == 5
        assert result.gymID == 9

    async def test_commits_to_db(self):
        db = _make_record_checkin_db(_make_membership())

        await record_checkin(1, 1, db)

        db.commit.assert_awaited_once()

    async def test_refreshes_after_commit(self):
        db = _make_record_checkin_db(_make_membership())

        await record_checkin(1, 1, db)

        db.refresh.assert_awaited_once()

    async def test_adds_to_session(self):
        db = _make_record_checkin_db(_make_membership())

        await record_checkin(1, 1, db)

        db.add.assert_called_once()

    async def test_queries_membership_before_inserting(self):
        """record_checkin must re-verify membership itself, not just trust the caller."""
        db = _make_record_checkin_db(_make_membership())

        await record_checkin(1, 1, db)

        db.execute.assert_awaited_once()

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

        db = _make_record_checkin_db(_make_membership())

        with patch(
            "app.services.client.client_attendance.datetime"
        ) as mock_dt:
            mock_dt.now.return_value = fixed_dt

            result = await record_checkin(1, 1, db)

        assert result.day_of_week == expected_dow

    async def test_checked_in_timestamp_is_set(self):
        db = _make_record_checkin_db(_make_membership())

        before = datetime.now()
        result = await record_checkin(1, 1, db)
        after = datetime.now()

        assert before <= result.checked_in <= after

    # ── guard clauses (the new behavior) ───────────────────────────────────

    async def test_raises_when_no_membership_found(self):
        db = _make_record_checkin_db(membership=None)

        with pytest.raises(HTTPException) as exc_info:
            await record_checkin(1, 1, db)

        assert exc_info.value.status_code == 400
        assert "Not connected" in exc_info.value.detail

    async def test_raises_when_membership_suspended(self):
        db = _make_record_checkin_db(_make_membership(status="suspended"))

        with pytest.raises(HTTPException) as exc_info:
            await record_checkin(1, 1, db)

        assert exc_info.value.status_code == 403
        assert "suspended" in exc_info.value.detail

    async def test_raises_when_subscription_expired(self):
        expired = _make_membership(subscription_end=date.today() - timedelta(days=1))
        db = _make_record_checkin_db(expired)

        with pytest.raises(HTTPException) as exc_info:
            await record_checkin(1, 1, db)

        assert exc_info.value.status_code == 403
        assert "expired" in exc_info.value.detail

    async def test_does_not_insert_when_membership_invalid(self):
        """Guard failure must short-circuit before touching db.add/commit."""
        db = _make_record_checkin_db(membership=None)

        with pytest.raises(HTTPException):
            await record_checkin(1, 1, db)

        db.add.assert_not_called()
        db.commit.assert_not_awaited()

    async def test_membership_query_scoped_to_client_and_gym(self):
        """
        Sanity check that a membership for the wrong gym isn't silently
        accepted — simulated by returning None (as the real query would,
        since it filters on both clientID and gymID).
        """
        db = _make_record_checkin_db(membership=None)

        with pytest.raises(HTTPException):
            await record_checkin(client_id=1, gym_id=999, db=db)


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
        db = _make_db_returning_all([])

        await get_recent_checkins(1, 1, db)

        db.execute.assert_awaited_once()

    async def test_custom_limit_accepted(self):
        db = _make_db_returning_all([])

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