# test/unit/client/test_client_schedule_service.py
#
# Run with:
#   pytest test/unit/client/test_client_schedule_service.py -v

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import date, timedelta, datetime, time

from app.services.client.client_schedule import (
    _next_occurrence,
    enroll,
    unenroll,
    get_my_classes,
    browse_classes,
    get_client_schedule_stats,
)
from app.models.class_session import ClassSession
from app.models.class_enrollment import ClassEnrollment
from app.models.gym_clients_membership import GymClientMembership


# ── Helpers ───────────────────────────────────────────────────────────────────

today = date.today()
yesterday = today - timedelta(days=1)
tomorrow = today + timedelta(days=1)

DAY_NAMES = ["monday", "tuesday", "wednesday", "thursday",
             "friday", "saturday", "sunday"]


def _make_session(
    session_id: int = 1,
    gym_id: int = 1,
    coach_id: int = 1,
    title: str = "Yoga",
    is_recurring: bool = True,
    day_of_week: str = "monday",
    class_date: date | None = None,
    start_time: str = "09:00",
    duration: int = 60,
    max_clients: int = 10,
) -> MagicMock:
    s = MagicMock(spec=ClassSession)
    s.id = session_id
    s.gymID = gym_id
    s.coach_id = coach_id
    s.title = title
    s.is_recurring = is_recurring
    s.day_of_week = day_of_week
    s.date = class_date
    s.start_time = start_time
    s.duration = duration
    s.max_clients = max_clients
    return s


def _make_enrollment(
    session_id: int = 1,
    client_id: int = 1,
    class_date: date = today,
) -> MagicMock:
    e = MagicMock(spec=ClassEnrollment)
    e.session_id = session_id
    e.clientID = client_id
    e.class_date = class_date
    return e


def _make_membership(
    status: str = "active",
    subscription_end: date = today + timedelta(days=30),
    gym_id: int = 1,
) -> MagicMock:
    """
    gym_id defaults to 1 to match _make_session()'s default gym_id=1 —
    enroll() now cross-checks session.gymID == membership.gymID, so any
    test exercising a *successful* enroll needs these to line up.
    """
    m = MagicMock(spec=GymClientMembership)
    m.status = status
    m.subscription_end = subscription_end
    m.gymID = gym_id
    return m


def _scalar_result(value) -> MagicMock:
    r = MagicMock()
    r.scalar_one_or_none.return_value = value
    return r


def _scalars_all_result(rows: list) -> MagicMock:
    r = MagicMock()
    r.scalars.return_value.all.return_value = rows
    return r


# ════════════════════════════════════════════════════════════════════════════
# _next_occurrence  (pure function)
# ════════════════════════════════════════════════════════════════════════════

class TestNextOccurrence:

    def test_returns_a_date(self):
        result = _next_occurrence("monday")
        assert isinstance(result, date)

    def test_result_is_always_in_future(self):
        for day in DAY_NAMES:
            result = _next_occurrence(day)
            assert result > today

    def test_today_weekday_skips_to_next_week(self):
        today_name = DAY_NAMES[today.weekday()]
        result = _next_occurrence(today_name)
        assert result == today + timedelta(days=7)

    def test_returns_correct_weekday(self):
        for i, day in enumerate(DAY_NAMES):
            result = _next_occurrence(day)
            assert result.weekday() == i

    def test_result_at_most_7_days_away(self):
        for day in DAY_NAMES:
            result = _next_occurrence(day)
            assert (result - today).days <= 7

    def test_case_insensitive(self):
        lower = _next_occurrence("monday")
        upper = _next_occurrence("MONDAY")
        assert lower == upper


# ════════════════════════════════════════════════════════════════════════════
# enroll
# ════════════════════════════════════════════════════════════════════════════

class TestEnroll:

    def _make_db(self, membership, session, existing_enrollment=None, enrolled_count=0):
        db = AsyncMock()
        db.execute = AsyncMock(side_effect=[
            _scalar_result(membership),   # get_membership
            _scalar_result(session),      # ClassSession lookup
            _scalar_result(existing_enrollment),  # _get_enrollment
        ])
        db.scalar = AsyncMock(return_value=enrolled_count)  # _count_enrolled
        db.add = MagicMock()
        db.commit = AsyncMock()
        return db

    async def test_success_returns_message(self):
        membership = _make_membership()
        session = _make_session(max_clients=10)
        db = self._make_db(membership, session)

        result = await enroll(1, 1, tomorrow, db)

        assert result["message"] == "Enrolled successfully"

    async def test_success_returns_correct_fields(self):
        membership = _make_membership()
        session = _make_session(session_id=5, title="Spin", start_time="10:00")
        db = self._make_db(membership, session)

        result = await enroll(5, 1, tomorrow, db)

        assert result["session_id"] == 5
        assert result["title"] == "Spin"
        assert result["start_time"] == "10:00"
        assert result["class_date"] == str(tomorrow)

    async def test_error_when_no_membership(self):
        db = AsyncMock()
        db.execute = AsyncMock(return_value=_scalar_result(None))

        result = await enroll(1, 1, tomorrow, db)

        assert "error" in result
        assert "not connected to a gym" in result["error"]

    async def test_error_when_membership_suspended(self):
        membership = _make_membership(status="suspended")
        db = AsyncMock()
        db.execute = AsyncMock(return_value=_scalar_result(membership))

        result = await enroll(1, 1, tomorrow, db)

        assert "error" in result
        assert "suspended" in result["error"].lower()

    async def test_error_when_subscription_expired(self):
        membership = _make_membership(
            status="active",
            subscription_end=yesterday,
        )
        db = AsyncMock()
        db.execute = AsyncMock(return_value=_scalar_result(membership))

        result = await enroll(1, 1, tomorrow, db)

        assert "error" in result
        assert "expired" in result["error"].lower()

    async def test_error_when_class_not_found(self):
        membership = _make_membership()
        db = AsyncMock()
        db.execute = AsyncMock(side_effect=[
            _scalar_result(membership),
            _scalar_result(None),  # session not found
        ])

        result = await enroll(99, 1, tomorrow, db)

        assert result["error"] == "Class not found"

    async def test_error_when_session_belongs_to_different_gym(self):
        """
        The core new behavior: a client with a valid, active membership at
        gym A must not be able to enroll in a session that belongs to gym B,
        even though get_membership() and the session lookup individually
        succeed — only the cross-check catches this.
        """
        membership = _make_membership(gym_id=1)
        session = _make_session(gym_id=2)
        db = AsyncMock()
        db.execute = AsyncMock(side_effect=[
            _scalar_result(membership),
            _scalar_result(session),
        ])

        result = await enroll(1, 1, tomorrow, db)

        assert "error" in result
        assert "does not belong to your gym" in result["error"]

    async def test_does_not_check_enrollment_or_commit_on_gym_mismatch(self):
        """Gym mismatch must short-circuit before any enrollment/count/commit calls."""
        membership = _make_membership(gym_id=1)
        session = _make_session(gym_id=2)
        db = AsyncMock()
        db.execute = AsyncMock(side_effect=[
            _scalar_result(membership),
            _scalar_result(session),
        ])
        db.scalar = AsyncMock(return_value=0)
        db.add = MagicMock()
        db.commit = AsyncMock()

        await enroll(1, 1, tomorrow, db)

        db.add.assert_not_called()
        db.commit.assert_not_awaited()

    async def test_error_when_already_enrolled(self):
        membership = _make_membership()
        session = _make_session()
        existing = _make_enrollment()
        db = AsyncMock()
        db.execute = AsyncMock(side_effect=[
            _scalar_result(membership),
            _scalar_result(session),
            _scalar_result(existing),  # already enrolled
        ])

        result = await enroll(1, 1, tomorrow, db)

        assert "Already enrolled" in result["error"]

    async def test_error_when_class_is_full(self):
        membership = _make_membership()
        session = _make_session(max_clients=5)
        db = AsyncMock()
        db.execute = AsyncMock(side_effect=[
            _scalar_result(membership),
            _scalar_result(session),
            _scalar_result(None),  # not enrolled yet
        ])
        db.scalar = AsyncMock(return_value=5)  # count == max

        result = await enroll(1, 1, tomorrow, db)

        assert "full" in result["error"].lower()

    async def test_commits_on_success(self):
        membership = _make_membership()
        session = _make_session(max_clients=10)
        db = self._make_db(membership, session)

        await enroll(1, 1, tomorrow, db)

        db.commit.assert_awaited_once()

    async def test_adds_enrollment_to_session(self):
        membership = _make_membership()
        session = _make_session(max_clients=10)
        db = self._make_db(membership, session)

        await enroll(1, 1, tomorrow, db)

        db.add.assert_called_once()


# ════════════════════════════════════════════════════════════════════════════
# unenroll
# ════════════════════════════════════════════════════════════════════════════

class TestUnenroll:

    async def test_success_returns_message(self):
        enrollment = _make_enrollment()
        db = AsyncMock()
        db.execute = AsyncMock(return_value=_scalar_result(enrollment))
        db.delete = AsyncMock()
        db.commit = AsyncMock()

        result = await unenroll(1, 1, tomorrow, db)

        assert result["message"] == "Unenrolled successfully"

    async def test_error_when_not_enrolled(self):
        db = AsyncMock()
        db.execute = AsyncMock(return_value=_scalar_result(None))

        result = await unenroll(1, 1, tomorrow, db)

        assert result["error"] == "Not enrolled for this date"

    async def test_deletes_enrollment_on_success(self):
        enrollment = _make_enrollment()
        db = AsyncMock()
        db.execute = AsyncMock(return_value=_scalar_result(enrollment))
        db.delete = AsyncMock()
        db.commit = AsyncMock()

        await unenroll(1, 1, tomorrow, db)

        db.delete.assert_awaited_once_with(enrollment)

    async def test_commits_on_success(self):
        enrollment = _make_enrollment()
        db = AsyncMock()
        db.execute = AsyncMock(return_value=_scalar_result(enrollment))
        db.delete = AsyncMock()
        db.commit = AsyncMock()

        await unenroll(1, 1, tomorrow, db)

        db.commit.assert_awaited_once()

    async def test_does_not_commit_when_not_enrolled(self):
        db = AsyncMock()
        db.execute = AsyncMock(return_value=_scalar_result(None))
        db.commit = AsyncMock()

        await unenroll(1, 1, tomorrow, db)

        db.commit.assert_not_awaited()


# ════════════════════════════════════════════════════════════════════════════
# get_my_classes
# ════════════════════════════════════════════════════════════════════════════

class TestGetMyClasses:

    async def test_returns_empty_when_no_gym(self):
        with patch(
            "app.services.client.client_schedule.get_client_gymID",
            new=AsyncMock(return_value=None),
        ):
            result = await get_my_classes(1, AsyncMock())
        assert result == []

    async def test_returns_empty_when_no_sessions(self):
        db = AsyncMock()
        db.execute = AsyncMock(return_value=_scalars_all_result([]))

        with patch(
            "app.services.client.client_schedule.get_client_gymID",
            new=AsyncMock(return_value=1),
        ):
            result = await get_my_classes(1, db)
        assert result == []

    async def test_recurring_class_only_returned_if_enrolled(self):
        session = _make_session(is_recurring=True, day_of_week="monday")
        db = AsyncMock()
        db.execute = AsyncMock(side_effect=[
            _scalars_all_result([session]),  # sessions query
            _scalar_result(None),            # _get_enrollment → not enrolled
        ])

        with patch(
            "app.services.client.client_schedule.get_client_gymID",
            new=AsyncMock(return_value=1),
        ):
            result = await get_my_classes(1, db)

        assert result == []

    async def test_past_one_time_class_excluded(self):
        session = _make_session(is_recurring=False, day_of_week=None, class_date=yesterday)
        db = AsyncMock()
        db.execute = AsyncMock(return_value=_scalars_all_result([session]))

        with patch(
            "app.services.client.client_schedule.get_client_gymID",
            new=AsyncMock(return_value=1),
        ):
            result = await get_my_classes(1, db)

        assert result == []

    async def test_future_one_time_class_included_if_enrolled(self):
        session = _make_session(is_recurring=False, day_of_week=None, class_date=tomorrow)
        enrollment = _make_enrollment(class_date=tomorrow)

        with patch(
            "app.services.client.client_schedule.get_client_gymID",
            new=AsyncMock(return_value=1),
        ), patch(
            "app.services.client.client_schedule._get_enrollment",
            new=AsyncMock(return_value=enrollment),
        ), patch(
            "app.services.client.client_schedule._build_class_response",
            new=AsyncMock(return_value={"id": 1}),
        ):
            db = AsyncMock()
            db.execute = AsyncMock(return_value=_scalars_all_result([session]))
            result = await get_my_classes(1, db)

        assert len(result) == 1


# ════════════════════════════════════════════════════════════════════════════
# browse_classes
# ════════════════════════════════════════════════════════════════════════════

class TestBrowseClasses:

    async def test_returns_empty_when_no_gym(self):
        with patch(
            "app.services.client.client_schedule.get_client_gymID",
            new=AsyncMock(return_value=None),
        ):
            result = await browse_classes(1, AsyncMock())
        assert result == []

    async def test_past_one_time_classes_excluded(self):
        session = _make_session(is_recurring=False, day_of_week=None, class_date=yesterday)
        db = AsyncMock()
        db.execute = AsyncMock(return_value=_scalars_all_result([session]))

        with patch(
            "app.services.client.client_schedule.get_client_gymID",
            new=AsyncMock(return_value=1),
        ):
            result = await browse_classes(1, db)

        assert result == []

    async def test_recurring_class_always_included(self):
        session = _make_session(is_recurring=True, day_of_week="monday")

        with patch(
            "app.services.client.client_schedule.get_client_gymID",
            new=AsyncMock(return_value=1),
        ), patch(
            "app.services.client.client_schedule._build_class_response",
            new=AsyncMock(return_value={"id": 1}),
        ):
            db = AsyncMock()
            db.execute = AsyncMock(return_value=_scalars_all_result([session]))
            result = await browse_classes(1, db)

        assert len(result) == 1

    async def test_future_one_time_class_included(self):
        session = _make_session(is_recurring=False, day_of_week=None, class_date=tomorrow)

        with patch(
            "app.services.client.client_schedule.get_client_gymID",
            new=AsyncMock(return_value=1),
        ), patch(
            "app.services.client.client_schedule._build_class_response",
            new=AsyncMock(return_value={"id": 1}),
        ):
            db = AsyncMock()
            db.execute = AsyncMock(return_value=_scalars_all_result([session]))
            result = await browse_classes(1, db)

        assert len(result) == 1

    async def test_returns_empty_when_no_sessions(self):
        db = AsyncMock()
        db.execute = AsyncMock(return_value=_scalars_all_result([]))

        with patch(
            "app.services.client.client_schedule.get_client_gymID",
            new=AsyncMock(return_value=1),
        ):
            result = await browse_classes(1, db)

        assert result == []


# ════════════════════════════════════════════════════════════════════════════
# get_client_schedule_stats
# ════════════════════════════════════════════════════════════════════════════

class TestGetClientScheduleStats:

    def _make_row(self, class_date: date, start_time: time) -> tuple:
        enrollment = MagicMock()
        enrollment.clientID = 1
        enrollment.class_date = class_date
        session = MagicMock()
        session.start_time = start_time
        return (enrollment, session)

    async def test_returns_correct_keys(self):
        db = AsyncMock()
        db.execute = AsyncMock(return_value=MagicMock(all=MagicMock(return_value=[])))
        db.scalar = AsyncMock(return_value=0)

        result = await get_client_schedule_stats(1, db)

        assert set(result.keys()) == {"enrolled", "upcoming", "minutes_week"}

    async def test_future_class_counts_as_active(self):
        row = self._make_row(tomorrow, time(9, 0))
        rows_mock = MagicMock()
        rows_mock.all.return_value = [row]

        db = AsyncMock()
        db.execute = AsyncMock(return_value=rows_mock)
        db.scalar = AsyncMock(return_value=0)

        result = await get_client_schedule_stats(1, db)

        assert result["enrolled"] == 1

    async def test_no_enrollments_returns_zeros(self):
        rows_mock = MagicMock()
        rows_mock.all.return_value = []

        db = AsyncMock()
        db.execute = AsyncMock(return_value=rows_mock)
        db.scalar = AsyncMock(return_value=0)

        result = await get_client_schedule_stats(1, db)

        assert result["enrolled"] == 0
        assert result["upcoming"] == 0

    async def test_minutes_week_always_zero(self):
        rows_mock = MagicMock()
        rows_mock.all.return_value = []

        db = AsyncMock()
        db.execute = AsyncMock(return_value=rows_mock)
        db.scalar = AsyncMock(return_value=0)

        result = await get_client_schedule_stats(1, db)

        assert result["minutes_week"] == 0

    async def test_past_month_count_from_scalar(self):
        rows_mock = MagicMock()
        rows_mock.all.return_value = []

        db = AsyncMock()
        db.execute = AsyncMock(return_value=rows_mock)
        db.scalar = AsyncMock(return_value=7)

        result = await get_client_schedule_stats(1, db)

        assert result["upcoming"] == 7