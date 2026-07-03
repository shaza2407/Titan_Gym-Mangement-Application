# tests/unit/coach/test_coach_schedule.py

import pytest
from datetime import date, time, timedelta
from unittest.mock import MagicMock, AsyncMock
from fastapi import HTTPException

from app.services.coach.coach_schedule import (
    _active_gym_join,
    get_coach_or_404,
    _next_occurrence,
    get_gym_name,
    get_coach_gymID,
    _count_enrolled,
    get_schedule_stats,
    get_weekly_schedule,
    get_my_classes,
    get_class_requests,
    create_class_request,
    remove_class_request,
    get_coach_gyms_lookup,
)

from app.models.class_session import ClassSession
from test.unit.coach.helpers import (
    make_coach,
    make_session,
    mock_execute_returning,
    mock_execute_scalars,
)

# ── get_coach_or_404 test suite ────────────────────────────────────────────────────
class TestGetCoachOr404:
    async def test_returns_coach_if_found(self, mock_db):
        coach = make_coach()
        mock_execute_returning(mock_db, coach)

        result = await get_coach_or_404(1, mock_db)
        assert result is coach

    async def test_raises_http_exception_if_not_found(self, mock_db):
        mock_execute_returning(mock_db, None)

        with pytest.raises(HTTPException) as exc_info:
            await get_coach_or_404(1, mock_db)
        
        assert exc_info.value.status_code == 404

# ── get_coach_gymID test suite ─────────────────────────────────────────────────────
class TestGetCoachGymID:
    async def test_returns_gym_id_(self, mock_db):
        mock_execute_returning(mock_db, 100)
        gym_id = await get_coach_gymID(6, mock_db)
        assert gym_id == 100

    async def test_returns_none_if_not_found(self, mock_db):
        mock_execute_returning(mock_db, None)
        gym_id = await get_coach_gymID(6, mock_db)
        assert gym_id is None

# ── get_gym_name test suite ────────────────────────────────────────────────────────
class TestGetGymName:
    async def test_returns_gym_name_if_found(self, mock_db):
        mock_execute_returning(mock_db, "Test Gym")
        name = await get_gym_name(1, mock_db)
        assert name == "Test Gym"

    async def test_returns_none_if_not_found(self, mock_db):
        mock_execute_returning(mock_db, None)
        name = await get_gym_name(1, mock_db)
        assert name is None

# ── _next_occurrence test suite ────────────────────────────────────────────────────
class TestNextOccurrence:
    days = ["monday", "tuesday", "wednesday", "thursday",
            "friday", "saturday", "sunday"]

    def test_returns_a_future_date(self):
        for day in self.days:
            result = _next_occurrence(day)
            assert result > date.today()
    
    def test_returns_date_at_most_seven_days_in_future(self):
        for day in self.days:
            result = _next_occurrence(day)
            assert result <= date.today() + timedelta(days=7)

    def test_case_insensitive(self):
        lower = _next_occurrence("monday")
        upper = _next_occurrence("MONDAY")
        mixed = _next_occurrence("MonDay")
        assert lower == upper == mixed

# ── _count_enrolled test suite ─────────────────────────────────────────────────────
class TestCountEnrolled:
    async def test_returns_count(self, mock_db):
        mock_db.scalar.return_value = 5
        count = await _count_enrolled(1, date.today(), mock_db)
        assert count == 5

    async def test_returns_zero_when_none(self, mock_db):
        mock_db.scalar.return_value = None
        count = await _count_enrolled(1, date.today(), mock_db)
        assert count == 0


# ── _active_gym_join test suite ─────────────────────────────────────────────────────
class TestActiveGymJoin:
    def _get_clauses(self, coachID, TargetModel):
        result = _active_gym_join(coachID, TargetModel)
        return list(result)
    
    def test_returns_three_top_level_clauses(self):
        clauses = self._get_clauses(1, ClassSession)
        assert len(clauses) == 3

    def test_accepts_different_target_models(self):
        from app.models.class_request import ClassRequest
        clauses1 = self._get_clauses(1, ClassSession)
        clauses2 = self._get_clauses(1, ClassRequest)
        assert clauses1 != clauses2


# ── get_schedule_stats test suite ──────────────────────────────────────────────────
class TestGetScheduleStats:
    async def test_counts_recurring_sessions_in_window(self, mock_db, recurring_session):
        days = ["monday", "tuesday", "wednesday", "thursday",
                "friday", "saturday", "sunday"]
        today_name = days[date.today().weekday()]

        recurring_session.day_of_week = today_name
        mock_execute_scalars(mock_db, [recurring_session])
        # client, pending requests count
        mock_db.scalar.return_value = 0  

        stats = await get_schedule_stats(10, mock_db)
        assert stats["weekly_classes"] == 1   

    async def test_counts_one_time_session_from_today(self, mock_db, one_time_session):
        mock_execute_scalars(mock_db, [one_time_session])
        mock_db.scalar.return_value = 0  

        stats = await get_schedule_stats(10, mock_db)
        assert stats["weekly_classes"] == 1

    async def test_excludes_past_one_time_sessions(self, mock_db, past_one_time_session):
        mock_execute_scalars(mock_db, [past_one_time_session])
        mock_db.scalar.return_value = 0  

        stats = await get_schedule_stats(10, mock_db)
        assert stats["weekly_classes"] == 0

    async def test_returns_pending_requests_count(self, mock_db):
        mock_execute_scalars(mock_db, [])
        mock_db.scalar.return_value = 3  

        stats = await get_schedule_stats(10, mock_db)
        assert stats["pending_requests"] == 3

    async def test_returns_zero_defaults_for_empty_schedule(self, mock_db):
        mock_execute_scalars(mock_db, [])
        mock_db.scalar.return_value = 0  

        stats = await get_schedule_stats(10, mock_db)
        assert stats == {
            "weekly_classes": 0,
            "total_clients": 0,
            "pending_requests": 0
        }

# ── get_weekly_schedule test suite ──────────────────────────────────────────────────
class TestGetWeeklyClasses:
    async def test_returns_7_days(self, mock_db):
        mock_execute_scalars(mock_db, [])
        mock_db.scalar.return_value = 0

        stats = await get_weekly_schedule(10, mock_db)
        assert len(stats) == 7

    async def test_recurring_session_placed_on_correct_day(self, mock_db, recurring_session):
        days = ["monday", "tuesday", "wednesday", "thursday",
                "friday", "saturday", "sunday"]
        today_name = days[date.today().weekday()]
        recurring_session.day_of_week = today_name

        mock_execute_scalars(mock_db, [recurring_session])
        mock_db.scalar.return_value = 0

        gym_name_result = MagicMock()
        gym_name_result.scalar_one_or_none.return_value = "Test Gym"

        scalars_result = MagicMock()
        scalars_result.scalars.return_value.all.return_value = [recurring_session]
        mock_db.execute.side_effect = [scalars_result, gym_name_result]
        # count enrolled clients
        mock_db.scalar.return_value = 2

        schedule = await get_weekly_schedule(10, mock_db)

        today_entry = schedule[0]
        assert len(today_entry["classes"]) == 1
        assert today_entry["classes"][0]["title"] == "Morning Yoga"

    async def test_empty_days_have_empty_classes_list(self, mock_db):
        mock_execute_scalars(mock_db, [])
        mock_db.scalar.return_value = 0

        schedule = await get_weekly_schedule(10, mock_db)

        for day_entry in schedule:
            assert day_entry["classes"] == []

    async def test_classes_sorted_by_start_time(self, mock_db):
        days = ["monday", "tuesday", "wednesday", "thursday",
                "friday", "saturday", "sunday"]
        today_name = days[date.today().weekday()]

        s1 = make_session(id=1, start_time=time(14, 0), day_of_week="monday")
        s2 = make_session(id=2, start_time=time(8, 0),  day_of_week="monday")

        s1.day_of_week = today_name
        s2.day_of_week = today_name

        scalars_result = MagicMock()
        scalars_result.scalars.return_value.all.return_value = [s1, s2]

        gym_name_result = MagicMock()
        gym_name_result.scalar_one_or_none.return_value = "Test Gym"

        mock_db.execute.side_effect = [scalars_result, gym_name_result, gym_name_result]
        mock_db.scalar.return_value = 0

        schedule = await get_weekly_schedule(10, mock_db)

        today_classes = schedule[0]["classes"]
        assert len(today_classes) == 2
        assert today_classes[0]["start_time"] <= today_classes[1]["start_time"]

# ── get_my_classes test suite ──────────────────────────────────────────────────────
class TestGetMyClasses:
    async def test_filters_out_past_sessions(self, mock_db, past_one_time_session):
        scalars_result = MagicMock()
        scalars_result.scalars.return_value.all.return_value = [past_one_time_session]

        mock_db.execute.side_effect = [scalars_result]
        mock_db.scalar.return_value = 0

        classes = await get_my_classes(10, mock_db)
        assert classes == []
    
    async def test_returns_empty_list_when_no_sessions(self, mock_db):
        mock_execute_scalars(mock_db, [])
        classes = await get_my_classes(10, mock_db)
        assert classes == []

    async def test_each_entry_contains_required_fields(self, mock_db, recurring_session):
        scalars_result = MagicMock()
        scalars_result.scalars.return_value.all.return_value = [recurring_session]

        gym_name_result = MagicMock()
        gym_name_result.scalar_one_or_none.return_value = "Test Gym"

        mock_db.execute.side_effect = [scalars_result, gym_name_result]
        mock_db.scalar.return_value = 0

        classes = await get_my_classes(10, mock_db)

        required_keys = {
            "id", "title", "day_of_week", "date", "start_time",
            "duration", "is_recurring", "gym_name", "current_clients", "max_clients",
        }
        assert required_keys.issubset(classes[0].keys())

# ── get_class_requests test suite ──────────────────────────────────────────────────
class TestGetClassRequests:
    async def test_returns_list_of_requests(self, mock_db, pending_request):
        mock_execute_scalars(mock_db, [pending_request])
        requests = await get_class_requests(10, mock_db)

        assert len(requests) == 1
        assert requests[0]["class_name"] == "Pilates"
        assert requests[0]["status"] == "pending"
    
    async def test_returns_empty_list_when_none(self, mock_db):
        mock_execute_scalars(mock_db, [])
        requests = await get_class_requests(10, mock_db)
        assert requests == []

    async def test_each_entry_has_required_keys(self, mock_db, pending_request):
        mock_execute_scalars(mock_db, [pending_request])
        requests = await get_class_requests(10, mock_db)
 
        required_keys = {
            "id", "coach_id", "gymID", "class_name", "is_recurring",
            "day_of_week", "requested_date", "requested_time", "duration",
            "max_capacity", "reason_for_request", "status", "created_at",
        }
        assert required_keys.issubset(requests[0].keys())
    
# ── create_class_request test suite ────────────────────────────────────────────────
class TestCreateClassRequest:
    async def test_raises_if_class_already_exists_at_time(
        self, mock_db, create_class_payload
    ):
        membership_result = MagicMock()
        mock_db.execute.return_value = membership_result

        # db.scalar returns an existing class → conflict
        mock_db.scalar.side_effect = [MagicMock(), None]
 
        with pytest.raises(HTTPException) as exc:
            await create_class_request(10, 100, create_class_payload, mock_db)
        assert exc.value.status_code == 400
        assert "already have a class" in exc.value.detail

    async def test_raises_if_pending_request_exists(
        self, mock_db, create_class_payload
    ):
        membership_result = MagicMock()
        mock_db.execute.return_value = membership_result

        # A pending request exists
        mock_db.scalar.side_effect = [None, MagicMock()]
 
        with pytest.raises(HTTPException) as exc:
            await create_class_request(10, 100, create_class_payload, mock_db)
        assert exc.value.status_code == 400
        assert "pending request" in exc.value.detail

    async def test_creates_request_successfully(
        self, mock_db, create_class_payload
    ):
        mock_db.scalar.side_effect = [None, None, None]
        mock_db.refresh = AsyncMock()
 
        gym_name_result = MagicMock()
        gym_name_result.scalar_one_or_none.return_value = "Test Gym"
        mock_db.execute.return_value = gym_name_result
 
        result = await create_class_request(10, 100, create_class_payload, mock_db)
 
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
        assert result["message"] == "Request submitted successfully"

    async def test_notifies_admin_after_creation(
        self, mock_db, create_class_payload, mock_notifications
    ):
        mock_db.scalar.side_effect = [None, None, None]
        gym_name_result = MagicMock()
        gym_name_result.scalar_one_or_none.return_value = "Test Gym"
        mock_db.execute.return_value = gym_name_result
 
        await create_class_request(10, 100, create_class_payload, mock_db)
 
        mock_notifications["admin"].assert_called_once()
    
# ── remove_class_request test suite ────────────────────────────────────────────────
class TestRemoveClassRequest:
    async def test_raises_404_if_not_found(self, mock_db):
        mock_execute_returning(mock_db, None)
 
        with pytest.raises(HTTPException) as exc:
            await remove_class_request(10, 999, mock_db)
        assert exc.value.status_code == 404
 
    async def test_raises_400_if_not_pending(self, mock_db, approved_request):
        mock_execute_returning(mock_db, approved_request)
 
        with pytest.raises(HTTPException) as exc:
            await remove_class_request(10, 2, mock_db)
        assert exc.value.status_code == 400
        assert "pending" in exc.value.detail
 
    async def test_deletes_successfully_pending_request(self, mock_db, pending_request):
        # 1. Class request lookup
        first_result = MagicMock()
        first_result.scalar_one_or_none.return_value = pending_request
        
        # 2. Gym membership check
        membership_result = MagicMock()
        membership_result.scalar_one_or_none.return_value = MagicMock() 

        # 3. Notification deletion
        notif_result = MagicMock()

        # Wire up all three expected queries sequentially
        mock_db.execute.side_effect = [first_result, membership_result, notif_result]
 
        result = await remove_class_request(10, 1, mock_db)
 
        mock_db.delete.assert_called_once_with(pending_request)
        mock_db.commit.assert_called_once()
        assert result is True
 
# ── get_coach_gyms_lookup test suite ───────────────────────────────────────────────
class TestGetCoachGymsLookup:
    async def test_returns_gym_id_and_name_pairs(self, mock_db):
        row1 = MagicMock()
        row1.gymID = 100
        row1.gymName = "FitZone"
        row1.status.value = "active"

        row2 = MagicMock()
        row2.gymID = 200
        row2.gymName = "Test Gym"
        row2.status.value = "suspended"
 
        result_mock = MagicMock()
        result_mock.all.return_value = [row1, row2]
        mock_db.execute.return_value = result_mock
 
        gyms = await get_coach_gyms_lookup(10, mock_db)
 
        assert len(gyms) == 2
        assert gyms[0] == {"id": 100, "name": "FitZone", "status": "active"}
        assert gyms[1] == {"id": 200, "name": "Test Gym", "status": "suspended"}
 
    async def test_returns_empty_list_when_no_gyms(self, mock_db):
        result_mock = MagicMock()
        result_mock.all.return_value = []
        mock_db.execute.return_value = result_mock
 
        gyms = await get_coach_gyms_lookup(10, mock_db)
 
        assert gyms == []