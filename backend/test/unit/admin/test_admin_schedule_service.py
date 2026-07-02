# Unit tests for app/services/admin_schedule.py
#
# Run with: 
#       pytest test/services/admin/test_admin_schedule_service.py -v


import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import date, time, datetime, timedelta 
from sqlalchemy.ext.asyncio import AsyncSession
from app.schemas.shared.schedule_schema import CreateClassRequest, EditClassRequest
from app.models.class_request import RequestStatus


# ---------------------------------------------------------------------------
# Module under test
# ---------------------------------------------------------------------------
from app.services.admin.admin_schedule import (
    # helpers
    _is_passed_today,
    _is_past_datetime,
    _next_weekday,
    # async helpers
    get_admin_gym_or_403,
    get_gym_name,
    _get_coach_name,
    _count_enrolled_for_session,
    _coach_belongs_to_gym,
    _coach_has_conflict,
    _gym_slot_conflict,
    # core service functions
    get_admin_schedule_stats,
    get_all_classes,
    create_class,
    delete_class,
    get_class_or_none,
    edit_class,
    get_pending_requests,
    approve_request,
    reject_request,
    get_class_members,
    get_gym_coaches,
)



# ===========================================================================
# Fixtures
# ===========================================================================

@pytest.fixture
def db() -> AsyncMock:
    """Minimal async DB session mock."""
    session = AsyncMock(spec=AsyncSession)
    session.add = MagicMock()
    return session


def _scalar_result(value):
    """Return an execute-result mock whose .scalar_one_or_none() returns value."""
    result = MagicMock()
    result.scalar_one_or_none.return_value = value
    result.scalars.return_value.all.return_value = value if isinstance(value, list) else []
    result.all.return_value = []
    return result


def _scalars_result(items: list):
    result = MagicMock()
    result.scalars.return_value.all.return_value = items
    result.scalar_one_or_none.return_value = items[0] if items else None
    result.all.return_value = items
    return result

from unittest.mock import patch as mock_patch

@pytest.fixture
def frozen_now():
    """Freeze datetime.now() used inside admin_schedule to a safe mid-day time."""
    fixed = datetime(2026, 7, 2, 12, 0, 0)  # noon — plenty of room before/after
    with mock_patch("app.services.admin.admin_schedule.datetime") as mock_dt:
        mock_dt.now.return_value = fixed
        mock_dt.combine = datetime.combine  # keep real combine()
        yield fixed

def make_session(**kwargs):
    """Factory for a ClassSession-like mock."""
    s = MagicMock()
    s.id            = kwargs.get("id", 1)
    s.title         = kwargs.get("title", "Yoga")
    s.coach_id      = kwargs.get("coach_id", 10)
    s.gymID         = kwargs.get("gymID", 5)
    s.is_recurring  = kwargs.get("is_recurring", True)
    s.day_of_week   = kwargs.get("day_of_week", "monday")
    s.date          = kwargs.get("date", None)
    s.start_time    = kwargs.get("start_time", "09:00")
    s.duration      = kwargs.get("duration", 60)
    s.max_clients   = kwargs.get("max_clients", 20)
    return s


def make_request(**kwargs):
    req = MagicMock()
    req.id                = kwargs.get("id", 1)
    req.coach_id          = kwargs.get("coach_id", 10)
    req.gymID             = kwargs.get("gymID", 5)
    req.class_name        = kwargs.get("class_name", "Pilates")
    req.is_recurring      = kwargs.get("is_recurring", False)
    req.day_of_week       = kwargs.get("day_of_week", None)
    req.requested_date    = kwargs.get("requested_date", date.today() + timedelta(days=1))
    req.requested_time    = kwargs.get("requested_time", "10:00")
    req.duration          = kwargs.get("duration", 45)
    req.max_capacity      = kwargs.get("max_capacity", 15)
    req.reason_for_request= kwargs.get("reason_for_request", "Popular demand")
    req.status            = kwargs.get("status", RequestStatus.PENDING)
    req.created_at        = kwargs.get("created_at", datetime.now())
    return req


def make_create_payload(**kwargs) -> CreateClassRequest:
    payload = MagicMock(spec=CreateClassRequest)
    payload.title         = kwargs.get("title", "Yoga")
    payload.coach_id      = kwargs.get("coach_id", 10)
    payload.is_recurring  = kwargs.get("is_recurring", True)
    payload.day_of_week   = kwargs.get("day_of_week", "monday")
    payload.date          = kwargs.get("date", None)
    payload.start_time    = kwargs.get("start_time", "09:00")
    payload.duration      = kwargs.get("duration", 60)
    payload.max_clients   = kwargs.get("max_clients", 20)
    return payload


def make_edit_payload(**kwargs) -> EditClassRequest:
    payload = MagicMock(spec=EditClassRequest)
    payload.title         = kwargs.get("title", None)
    payload.coach_id      = kwargs.get("coach_id", None)
    payload.is_recurring  = kwargs.get("is_recurring", None)
    payload.day_of_week   = kwargs.get("day_of_week", None)
    payload.date          = kwargs.get("date", None)
    payload.start_time    = kwargs.get("start_time", None)
    payload.duration      = kwargs.get("duration", None)
    payload.max_clients   = kwargs.get("max_clients", None)
    return payload


# ===========================================================================
# 1. Pure helper: _is_past_datetime
# ===========================================================================

class TestIsPastDatetime:
    def test_past_date_returns_true(self):
        yesterday = date.today() - timedelta(days=1)
        assert _is_past_datetime(yesterday, "09:00") is True

    def test_future_date_returns_false(self):
        tomorrow = date.today() + timedelta(days=1)
        assert _is_past_datetime(tomorrow, "09:00") is False

    def test_today_past_time_returns_true(self):
        t = time(0, 1)          # 00:01 — guaranteed past for any realistic test run
        assert _is_past_datetime(date.today(), t) is True

    def test_today_future_time_returns_false(self, frozen_now):
        future_time = (frozen_now + timedelta(hours=2)).strftime("%H:%M")
        assert _is_past_datetime(date.today(), future_time) is False

    def test_accepts_time_object(self):
        yesterday = date.today() - timedelta(days=1)
        assert _is_past_datetime(yesterday, time(9, 0)) is True

    def test_accepts_string_time(self):
        tomorrow = date.today() + timedelta(days=1)
        assert _is_past_datetime(tomorrow, "23:59") is False

    def test_midnight_string(self):
        yesterday = date.today() - timedelta(days=1)
        assert _is_past_datetime(yesterday, "00:00") is True


# ===========================================================================
# 2. Pure helper: _is_passed_today
# ===========================================================================

class TestIsPassedToday:
    TODAY = date.today()
    TODAY_WEEKDAY = ["monday","tuesday","wednesday","thursday",
                     "friday","saturday","sunday"][TODAY.weekday()]

    def test_recurring_wrong_day_returns_false(self):
        s = make_session(is_recurring=True, day_of_week="sunday", start_time="09:00")
        other_day = "monday" if self.TODAY_WEEKDAY != "monday" else "tuesday"
        s.day_of_week = other_day
        assert _is_passed_today(s, self.TODAY, self.TODAY_WEEKDAY) is False

    def test_recurring_today_past_time_returns_true(self):
        s = make_session(is_recurring=True, day_of_week=self.TODAY_WEEKDAY, start_time="00:01")
        assert _is_passed_today(s, self.TODAY, self.TODAY_WEEKDAY) is True

    # TestIsPassedToday.test_recurring_today_future_time_returns_false  
    def test_recurring_today_future_time_returns_false(self, frozen_now):
        future = (frozen_now + timedelta(hours=3)).strftime("%H:%M")
        s = make_session(is_recurring=True, day_of_week=self.TODAY_WEEKDAY, start_time=future)
        assert _is_passed_today(s, self.TODAY, self.TODAY_WEEKDAY) is False

    def test_one_time_wrong_date_returns_false(self):
        tomorrow = self.TODAY + timedelta(days=1)
        s = make_session(is_recurring=False, date=tomorrow, start_time="09:00")
        assert _is_passed_today(s, self.TODAY, self.TODAY_WEEKDAY) is False

    def test_one_time_today_past_time_returns_true(self):
        s = make_session(is_recurring=False, date=self.TODAY, start_time="00:01")
        assert _is_passed_today(s, self.TODAY, self.TODAY_WEEKDAY) is True


# ===========================================================================
# 3. Pure helper: _next_weekday
# ===========================================================================

class TestNextWeekday:
    def test_returns_future_date(self):
        today = date.today()
        day_name = ["monday","tuesday","wednesday","thursday",
                    "friday","saturday","sunday"][today.weekday()]
        result = _next_weekday(day_name)
        assert result > today

    def test_result_is_correct_weekday(self):
        result = _next_weekday("friday")
        assert result.strftime("%A").lower() == "friday"

    def test_same_weekday_gives_next_week(self):
        today = date.today()
        day_name = today.strftime("%A").lower()
        result = _next_weekday(day_name)
        assert (result - today).days == 7

    def test_case_insensitive(self):
        result = _next_weekday("MONDAY")
        assert result.strftime("%A").lower() == "monday"


# ===========================================================================
# 4. get_admin_gym_or_403
# ===========================================================================

class TestGetAdminGymOr403:
    @pytest.mark.asyncio
    async def test_returns_gym_id_when_found(self, db):
        gym_mock = MagicMock(); gym_mock.gymID = 5
        db.execute.return_value = _scalar_result(gym_mock)
        result = await get_admin_gym_or_403(adminID=1, gymID=5, db=db)
        assert result == 5

    @pytest.mark.asyncio
    async def test_raises_403_when_not_found(self, db):
        from fastapi import HTTPException
        db.execute.return_value = _scalar_result(None)
        with pytest.raises(HTTPException) as exc_info:
            await get_admin_gym_or_403(adminID=1, gymID=99, db=db)
        assert exc_info.value.status_code == 403

    @pytest.mark.asyncio
    async def test_raises_403_wrong_admin(self, db):
        from fastapi import HTTPException
        db.execute.return_value = _scalar_result(None)
        with pytest.raises(HTTPException):
            await get_admin_gym_or_403(adminID=999, gymID=5, db=db)


# ===========================================================================
# 5. _coach_belongs_to_gym
# ===========================================================================

class TestCoachBelongsToGym:
    @pytest.mark.asyncio
    async def test_returns_true_when_membership_exists(self, db):
        db.execute.return_value = _scalar_result(MagicMock())
        assert await _coach_belongs_to_gym(10, 5, db) is True

    @pytest.mark.asyncio
    async def test_returns_false_when_no_membership(self, db):
        db.execute.return_value = _scalar_result(None)
        assert await _coach_belongs_to_gym(10, 5, db) is False


# ===========================================================================
# 6. _coach_has_conflict
# ===========================================================================

class TestCoachHasConflict:
    @pytest.mark.asyncio
    async def test_recurring_conflict_returns_true(self, db):
        db.execute.return_value = _scalar_result(MagicMock())
        result = await _coach_has_conflict(
            coach_id=10, is_recurring=True, day_of_week="monday",
            class_date=None, start_time="09:00", db=db
        )
        assert result is True

    @pytest.mark.asyncio
    async def test_no_conflict_returns_false(self, db):
        db.execute.return_value = _scalar_result(None)
        result = await _coach_has_conflict(
            coach_id=10, is_recurring=True, day_of_week="monday",
            class_date=None, start_time="09:00", db=db
        )
        assert result is False

    @pytest.mark.asyncio
    async def test_invalid_combination_returns_false(self, db):
        # recurring=True but no day_of_week — edge case
        result = await _coach_has_conflict(
            coach_id=10, is_recurring=True, day_of_week=None,
            class_date=None, start_time="09:00", db=db
        )
        assert result is False

    @pytest.mark.asyncio
    async def test_one_time_conflict(self, db):
        db.execute.return_value = _scalar_result(MagicMock())
        future = date.today() + timedelta(days=3)
        result = await _coach_has_conflict(
            coach_id=10, is_recurring=False, day_of_week=None,
            class_date=future, start_time="10:00", db=db
        )
        assert result is True

    @pytest.mark.asyncio
    async def test_exclude_session_id_respected(self, db):
        db.execute.return_value = _scalar_result(None)
        result = await _coach_has_conflict(
            coach_id=10, is_recurring=True, day_of_week="tuesday",
            class_date=None, start_time="09:00", db=db,
            exclude_session_id=42,
        )
        assert result is False


# ===========================================================================
# 7. _gym_slot_conflict
# ===========================================================================

class TestGymSlotConflict:
    @pytest.mark.asyncio
    async def test_conflict_found(self, db):
        db.execute.return_value = _scalar_result(MagicMock())
        result = await _gym_slot_conflict(
            gym_id=5, is_recurring=True, day_of_week="wednesday",
            class_date=None, start_time="08:00", db=db
        )
        assert result is True

    @pytest.mark.asyncio
    async def test_no_conflict(self, db):
        db.execute.return_value = _scalar_result(None)
        result = await _gym_slot_conflict(
            gym_id=5, is_recurring=True, day_of_week="wednesday",
            class_date=None, start_time="08:00", db=db
        )
        assert result is False

    @pytest.mark.asyncio
    async def test_missing_day_and_date_returns_false(self, db):
        result = await _gym_slot_conflict(
            gym_id=5, is_recurring=True, day_of_week=None,
            class_date=None, start_time="08:00", db=db
        )
        assert result is False


# ===========================================================================
# 8. create_class
# ===========================================================================

class TestCreateClass:
    @pytest.mark.asyncio
    async def test_successful_recurring_creation(self, db):
        db.execute.return_value = _scalar_result(MagicMock())   # coach belongs
        with patch("app.services.admin.admin_schedule._coach_belongs_to_gym", return_value=True), \
             patch("app.services.admin.admin_schedule._coach_has_conflict", return_value=False), \
             patch("app.services.admin.admin_schedule._gym_slot_conflict", return_value=False):
            payload = make_create_payload(is_recurring=True, day_of_week="monday")
            session, err = await create_class(gymID=5, payload=payload, db=db)
        assert err is None
        db.add.assert_called_once()
        db.commit.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_one_time_in_past_returns_error(self, db):
        past_date = date.today() - timedelta(days=1)
        payload = make_create_payload(is_recurring=False, date=past_date, start_time="09:00")
        session, err = await create_class(gymID=5, payload=payload, db=db)
        assert session is None
        assert "future" in err.lower()

    @pytest.mark.asyncio
    async def test_one_time_missing_date_returns_error(self, db):
        payload = make_create_payload(is_recurring=False, date=None)
        session, err = await create_class(gymID=5, payload=payload, db=db)
        assert session is None
        assert "date is required" in err.lower()

    @pytest.mark.asyncio
    async def test_coach_not_in_gym_returns_error(self, db):
        with patch("app.services.admin.admin_schedule._coach_belongs_to_gym", return_value=False):
            payload = make_create_payload(is_recurring=True)
            session, err = await create_class(gymID=5, payload=payload, db=db)
        assert session is None
        assert "coach" in err.lower()

    @pytest.mark.asyncio
    async def test_coach_time_conflict_returns_error(self, db):
        with patch("app.services.admin.admin_schedule._coach_belongs_to_gym", return_value=True), \
             patch("app.services.admin.admin_schedule._coach_has_conflict", return_value=True):
            payload = make_create_payload(is_recurring=True)
            session, err = await create_class(gymID=5, payload=payload, db=db)
        assert session is None
        assert "coach" in err.lower()

    @pytest.mark.asyncio
    async def test_gym_slot_conflict_returns_error(self, db):
        with patch("app.services.admin.admin_schedule._coach_belongs_to_gym", return_value=True), \
             patch("app.services.admin.admin_schedule._coach_has_conflict", return_value=False), \
             patch("app.services.admin.admin_schedule._gym_slot_conflict", return_value=True):
            payload = make_create_payload(is_recurring=True)
            session, err = await create_class(gymID=5, payload=payload, db=db)
        assert session is None
        assert "time slot" in err.lower()

    @pytest.mark.asyncio
    async def test_one_time_today_future_time_succeeds(self, db, frozen_now):
        future_time = (frozen_now + timedelta(hours=2)).strftime("%H:%M")
        with patch("app.services.admin.admin_schedule._coach_belongs_to_gym", return_value=True), \
            patch("app.services.admin.admin_schedule._coach_has_conflict", return_value=False), \
            patch("app.services.admin.admin_schedule._gym_slot_conflict", return_value=False):
            payload = make_create_payload(
                is_recurring=False, date=date.today(), start_time=future_time
            )
            session, err = await create_class(gymID=5, payload=payload, db=db)
        assert err is None

    @pytest.mark.asyncio
    async def test_day_of_week_derived_from_date(self, db):
        """For one-time classes day_of_week should be inferred from date."""
        future = date.today() + timedelta(days=3)
        expected_day = future.strftime("%A").lower()
        with patch("app.services.admin.admin_schedule._coach_belongs_to_gym", return_value=True), \
             patch("app.services.admin.admin_schedule._coach_has_conflict", return_value=False), \
             patch("app.services.admin.admin_schedule._gym_slot_conflict", return_value=False):
            payload = make_create_payload(is_recurring=False, date=future, day_of_week=None,
                                          start_time="14:00")
            session, err = await create_class(gymID=5, payload=payload, db=db)
        # No error — day derived successfully
        assert err is None


# ===========================================================================
# 9. delete_class
# ===========================================================================

class TestDeleteClass:
    @pytest.mark.asyncio
    async def test_delete_existing_class(self, db):
        db.execute.return_value = _scalar_result(make_session())
        result = await delete_class(session_id=1, gymID=5, db=db)
        assert result is True
        db.commit.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_delete_nonexistent_class_returns_false(self, db):
        db.execute.return_value = _scalar_result(None)
        result = await delete_class(session_id=999, gymID=5, db=db)
        assert result is False

    @pytest.mark.asyncio
    async def test_delete_wrong_gym_returns_false(self, db):
        db.execute.return_value = _scalar_result(None)
        result = await delete_class(session_id=1, gymID=99, db=db)
        assert result is False


# ===========================================================================
# 10. get_class_or_none
# ===========================================================================

class TestGetClassOrNone:
    @pytest.mark.asyncio
    async def test_returns_session_when_found(self, db):
        s = make_session()
        db.execute.return_value = _scalar_result(s)
        result = await get_class_or_none(1, 5, db)
        assert result is s

    @pytest.mark.asyncio
    async def test_returns_none_when_not_found(self, db):
        db.execute.return_value = _scalar_result(None)
        result = await get_class_or_none(999, 5, db)
        assert result is None


# ===========================================================================
# 11. edit_class
# ===========================================================================

class TestEditClass:
    @pytest.mark.asyncio
    async def test_session_not_found_returns_error(self, db):
        db.execute.return_value = _scalar_result(None)
        payload = make_edit_payload(title="New Title")
        session, err = await edit_class(session_id=99, gymID=5, payload=payload, db=db)
        assert session is None
        assert "not found" in err.lower()

    @pytest.mark.asyncio
    async def test_edit_title_only(self, db):
        existing = make_session(is_recurring=True, day_of_week="tuesday")
        db.execute.return_value = _scalar_result(existing)
        payload = make_edit_payload(title="New Yoga")
        with patch("app.services.admin.admin_schedule._coach_has_conflict", return_value=False), \
             patch("app.services.admin.admin_schedule._gym_slot_conflict", return_value=False):
            session, err = await edit_class(1, 5, payload, db)
        assert err is None
        assert existing.title == "New Yoga"

    @pytest.mark.asyncio
    async def test_new_coach_not_in_gym_returns_error(self, db):
        existing = make_session(is_recurring=True, coach_id=10)
        db.execute.return_value = _scalar_result(existing)
        payload = make_edit_payload(coach_id=99)
        with patch("app.services.admin.admin_schedule._coach_belongs_to_gym", return_value=False):
            session, err = await edit_class(1, 5, payload, db)
        assert session is None
        assert "coach" in err.lower()

    @pytest.mark.asyncio
    async def test_edit_one_time_class_to_past_returns_error(self, db):
        past = date.today() - timedelta(days=1)
        existing = make_session(is_recurring=False, date=date.today() + timedelta(days=2))
        db.execute.return_value = _scalar_result(existing)
        payload = make_edit_payload(is_recurring=False, date=past, start_time="09:00")
        session, err = await edit_class(1, 5, payload, db)
        assert session is None
        assert "future" in err.lower()

    @pytest.mark.asyncio
    async def test_coach_conflict_on_edit_returns_error(self, db):
        existing = make_session(is_recurring=True)
        db.execute.return_value = _scalar_result(existing)
        payload = make_edit_payload(start_time="10:00")
        with patch("app.services.admin.admin_schedule._coach_has_conflict", return_value=True):
            session, err = await edit_class(1, 5, payload, db)
        assert session is None
        assert "coach" in err.lower()

    @pytest.mark.asyncio
    async def test_gym_slot_conflict_on_edit_returns_error(self, db):
        existing = make_session(is_recurring=True)
        db.execute.return_value = _scalar_result(existing)
        payload = make_edit_payload(start_time="11:00")
        with patch("app.services.admin.admin_schedule._coach_has_conflict", return_value=False), \
             patch("app.services.admin.admin_schedule._gym_slot_conflict", return_value=True):
            session, err = await edit_class(1, 5, payload, db)
        assert session is None
        assert "time slot" in err.lower()

    @pytest.mark.asyncio
    async def test_edit_recurring_clears_date(self, db):
        existing = make_session(is_recurring=False, date=date.today() + timedelta(days=2))
        db.execute.return_value = _scalar_result(existing)
        payload = make_edit_payload(is_recurring=True, day_of_week="friday")
        with patch("app.services.admin.admin_schedule._coach_has_conflict", return_value=False), \
             patch("app.services.admin.admin_schedule._gym_slot_conflict", return_value=False):
            session, err = await edit_class(1, 5, payload, db)
        assert err is None
        assert existing.date is None   # date cleared when switching to recurring

    @pytest.mark.asyncio
    async def test_same_coach_no_belongs_check(self, db):
        """When coach_id is unchanged, skip the belongs-to-gym check."""
        existing = make_session(is_recurring=True, coach_id=10)
        db.execute.return_value = _scalar_result(existing)
        payload = make_edit_payload(coach_id=None, title="Updated")  # no coach change
        with patch("app.services.admin.admin_schedule._coach_belongs_to_gym") as mock_belongs, \
             patch("app.services.admin.admin_schedule._coach_has_conflict", return_value=False), \
             patch("app.services.admin.admin_schedule._gym_slot_conflict", return_value=False):
            session, err = await edit_class(1, 5, payload, db)
        mock_belongs.assert_not_called()
        assert err is None


# ===========================================================================
# 12. get_pending_requests
# ===========================================================================

class TestGetPendingRequests:
    @pytest.mark.asyncio
    async def test_returns_formatted_list(self, db):
        req = make_request()
        result_mock = MagicMock()
        result_mock.scalars.return_value.all.return_value = [req]
        db.execute.return_value = result_mock
        with patch("app.services.admin.admin_schedule._get_coach_name", return_value="Alice"):
            items = await get_pending_requests(gymID=5, db=db)
        assert len(items) == 1
        assert items[0]["coach_name"] == "Alice"
        assert items[0]["status"] == RequestStatus.PENDING.value

    @pytest.mark.asyncio
    async def test_empty_gym_returns_empty_list(self, db):
        result_mock = MagicMock()
        result_mock.scalars.return_value.all.return_value = []
        db.execute.return_value = result_mock
        items = await get_pending_requests(gymID=5, db=db)
        assert items == []


# ===========================================================================
# 13. approve_request
# ===========================================================================

class TestApproveRequest:
    @pytest.mark.asyncio
    async def test_successful_approval(self, db):
        req = make_request(requested_date=date.today() + timedelta(days=2))
        db.execute.return_value = _scalar_result(req)
        with patch("app.services.admin.admin_schedule._is_past_datetime", return_value=False), \
             patch("app.services.admin.admin_schedule._coach_has_conflict", return_value=False), \
             patch("app.services.admin.admin_schedule._gym_slot_conflict", return_value=False):
            success, err = await approve_request(request_id=1, gymID=5, db=db)
        assert success is True
        assert err is None
        assert req.status == RequestStatus.APPROVED

    @pytest.mark.asyncio
    async def test_request_not_found_returns_false(self, db):
        db.execute.return_value = _scalar_result(None)
        success, err = await approve_request(1, 5, db)
        assert success is False
        assert "not found" in err.lower()

    @pytest.mark.asyncio
    async def test_past_class_cannot_be_approved(self, db):
        past_date = date.today() - timedelta(days=1)
        req = make_request(requested_date=past_date)
        db.execute.return_value = _scalar_result(req)
        with patch("app.services.admin.admin_schedule._is_past_datetime", return_value=True):
            success, err = await approve_request(1, 5, db)
        assert success is False
        assert "passed" in err.lower()

    @pytest.mark.asyncio
    async def test_coach_conflict_blocks_approval(self, db):
        req = make_request()
        db.execute.return_value = _scalar_result(req)
        with patch("app.services.admin.admin_schedule._is_past_datetime", return_value=False), \
             patch("app.services.admin.admin_schedule._coach_has_conflict", return_value=True):
            success, err = await approve_request(1, 5, db)
        assert success is False
        assert "coach" in err.lower()

    @pytest.mark.asyncio
    async def test_gym_slot_conflict_blocks_approval(self, db):
        req = make_request()
        db.execute.return_value = _scalar_result(req)
        with patch("app.services.admin.admin_schedule._is_past_datetime", return_value=False), \
             patch("app.services.admin.admin_schedule._coach_has_conflict", return_value=False), \
             patch("app.services.admin.admin_schedule._gym_slot_conflict", return_value=True):
            success, err = await approve_request(1, 5, db)
        assert success is False
        assert "time slot" in err.lower()

    @pytest.mark.asyncio
    async def test_recurring_request_approval(self, db):
        req = make_request(is_recurring=True, requested_date=None, day_of_week="thursday")
        db.execute.return_value = _scalar_result(req)
        with patch("app.services.admin.admin_schedule._coach_has_conflict", return_value=False), \
             patch("app.services.admin.admin_schedule._gym_slot_conflict", return_value=False):
            success, err = await approve_request(1, 5, db)
        assert success is True


# ===========================================================================
# 14. reject_request
# ===========================================================================

class TestRejectRequest:
    @pytest.mark.asyncio
    async def test_reject_pending_request(self, db):
        req = make_request()
        db.execute.return_value = _scalar_result(req)
        result = await reject_request(1, 5, db)
        assert result is True
        assert req.status == RequestStatus.REJECTED

    @pytest.mark.asyncio
    async def test_reject_nonexistent_request_returns_false(self, db):
        db.execute.return_value = _scalar_result(None)
        result = await reject_request(999, 5, db)
        assert result is False

    @pytest.mark.asyncio
    async def test_reject_already_processed_returns_false(self, db):
        db.execute.return_value = _scalar_result(None)  # already approved → not PENDING
        result = await reject_request(1, 5, db)
        assert result is False


# ===========================================================================
# 15. get_admin_schedule_stats
# ===========================================================================

class TestGetAdminScheduleStats:
    @pytest.mark.asyncio
    async def test_stats_structure(self, db):
        tomorrow = date.today() + timedelta(days=1)
        sessions = [
            make_session(is_recurring=True, day_of_week="tuesday", coach_id=1),
            make_session(is_recurring=False, date=tomorrow, day_of_week=None, coach_id=2),
        ]
        sessions_result = MagicMock()
        sessions_result.scalars.return_value.all.return_value = sessions

        enroll_result = MagicMock()
        enroll_result.all.return_value = []

        pending_scalar = AsyncMock(return_value=3)

        call_count = 0

        async def mock_execute(query):
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                return sessions_result
            return enroll_result

        db.execute.side_effect = mock_execute
        db.scalar = pending_scalar

        stats = await get_admin_schedule_stats(gymID=5, db=db)
        assert "total_classes" in stats
        assert "total_enrolled" in stats
        assert "total_coaches" in stats
        assert "pending_requests" in stats


# ===========================================================================
# 16. get_all_classes
# ===========================================================================

class TestGetAllClasses:
    @pytest.mark.asyncio
    async def test_returns_class_list(self, db):
        s = make_session(is_recurring=True, day_of_week="monday")
        sessions_result = MagicMock()
        sessions_result.scalars.return_value.all.return_value = [s]
        db.execute.return_value = sessions_result

        with patch("app.services.admin.admin_schedule._get_coach_name", return_value="Bob"), \
             patch("app.services.admin.admin_schedule._count_enrolled_for_session", return_value=5):
            classes = await get_all_classes(gymID=5, db=db)

        assert len(classes) == 1
        assert classes[0]["title"] == "Yoga"
        assert classes[0]["coach_name"] == "Bob"
        assert classes[0]["current_clients"] == 5

    @pytest.mark.asyncio
    async def test_week_filter_applied(self, db):
        sessions_result = MagicMock()
        sessions_result.scalars.return_value.all.return_value = []
        db.execute.return_value = sessions_result

        week_start = date.today()
        week_end = week_start + timedelta(days=6)
        classes = await get_all_classes(gymID=5, db=db, week_start=week_start, week_end=week_end)
        assert classes == []

    @pytest.mark.asyncio
    async def test_from_date_filter_applied(self, db):
        sessions_result = MagicMock()
        sessions_result.scalars.return_value.all.return_value = []
        db.execute.return_value = sessions_result

        classes = await get_all_classes(gymID=5, db=db, from_date=date.today())
        assert classes == []


# ===========================================================================
# 17. _count_enrolled_for_session
# ===========================================================================

class TestCountEnrolledForSession:
    @pytest.mark.asyncio
    async def test_recurring_count(self, db):
        db.scalar = AsyncMock(return_value=7)
        count = await _count_enrolled_for_session(1, True, None, db)
        assert count == 7

    @pytest.mark.asyncio
    async def test_one_time_count(self, db):
        db.scalar = AsyncMock(return_value=3)
        count = await _count_enrolled_for_session(1, False, date.today(), db)
        assert count == 3

    @pytest.mark.asyncio
    async def test_none_result_returns_zero(self, db):
        db.scalar = AsyncMock(return_value=None)
        count = await _count_enrolled_for_session(1, True, None, db)
        assert count == 0


# ===========================================================================
# 18. get_class_members
# ===========================================================================

class TestGetClassMembers:
    @pytest.mark.asyncio
    async def test_returns_empty_when_session_not_found(self, db):
        db.execute.return_value = _scalar_result(None)
        members = await get_class_members(99, 5, db)
        assert members == []

    @pytest.mark.asyncio
    async def test_returns_members(self, db):
        session_result = _scalar_result(make_session())

        enrollment = MagicMock()
        enrollment.class_date = date.today()
        enrollment.enrolled_at = datetime.now()

        user = MagicMock()
        user.name  = "John"
        user.email = "john@example.com"
        user.phone = "0501234567"

        client = MagicMock()
        client.clientID = 42

        enroll_result = MagicMock()
        enroll_result.all.return_value = [(enrollment, user, client)]

        call_count = 0
        async def mock_execute(q):
            nonlocal call_count
            call_count += 1
            return session_result if call_count == 1 else enroll_result

        db.execute.side_effect = mock_execute
        members = await get_class_members(1, 5, db)
        assert len(members) == 1
        assert members[0]["name"] == "John"


# ===========================================================================
# 19. get_gym_coaches
# ===========================================================================

class TestGetGymCoaches:
    @pytest.mark.asyncio
    async def test_returns_coach_list(self, db):
        result_mock = MagicMock()
        result_mock.all.return_value = [(10, "Alice"), (11, "Bob")]
        db.execute.return_value = result_mock

        coaches = await get_gym_coaches(gymID=5, db=db)
        assert len(coaches) == 2
        assert coaches[0] == {"coach_id": 10, "name": "Alice"}

    @pytest.mark.asyncio
    async def test_returns_empty_list_for_gym_with_no_coaches(self, db):
        result_mock = MagicMock()
        result_mock.all.return_value = []
        db.execute.return_value = result_mock

        coaches = await get_gym_coaches(gymID=5, db=db)
        assert coaches == []


# ===========================================================================
# 20. get_gym_name
# ===========================================================================

class TestGetGymName:
    @pytest.mark.asyncio
    async def test_returns_name(self, db):
        result_mock = MagicMock()
        result_mock.scalar_one_or_none.return_value = "Iron Paradise"
        db.execute.return_value = result_mock

        name = await get_gym_name(gymID=5, db=db)
        assert name == "Iron Paradise"

    @pytest.mark.asyncio
    async def test_returns_none_when_gym_not_found(self, db):
        result_mock = MagicMock()
        result_mock.scalar_one_or_none.return_value = None
        db.execute.return_value = result_mock

        name = await get_gym_name(gymID=99, db=db)
        assert name is None