# tests/unit/coach/test_coach_gyms.py
import pytest
from datetime import date, timedelta
from unittest.mock import MagicMock
from fastapi import HTTPException

from test.unit.coach.helpers import (
    make_coach,
    make_gym_coach_membership,
    make_session,
    make_announcement,
    mock_execute_returning,
)
from app.services.coach.coach_gyms import (
    verify_coach_gym,
    get_coach_active_gyms,
    get_coach_announcements,
)


# ── verify_coach_gym ──────────────────────────────────────────────────────────

class TestVerifyCoachGym:

    async def test_returns_gym_id_when_member(self, mock_db):
        membership = make_gym_coach_membership()
        mock_execute_returning(mock_db, membership)

        result = await verify_coach_gym(10, 100, mock_db)

        assert result == 100

    async def test_raises_403_when_not_a_member(self, mock_db):
        mock_execute_returning(mock_db, None)

        with pytest.raises(HTTPException) as exc:
            await verify_coach_gym(10, 999, mock_db)
        assert exc.value.status_code == 403
        assert "not an active member" in exc.value.detail


# ── get_coach_active_gyms ─────────────────────────────────────────────────────

class TestGetCoachActiveGyms:

    def _make_gym_row(self, gym_id=100, gym_name="Test Gym", location="Cairo",
                      coach_id=10, status_value="active"):
        row = MagicMock()
        row.gymID = gym_id
        row.gymName = gym_name
        row.location = location
        row.coachID = coach_id
        row.status = MagicMock()
        row.status.value = status_value
        return row

    async def test_returns_empty_list_when_coach_not_found(self, mock_db):
        # Coach query returns None
        coach_result = MagicMock()
        coach_result.scalar_one_or_none.return_value = None
        mock_db.execute.side_effect = [coach_result]

        result = await get_coach_active_gyms(1, mock_db)

        assert result == []

    async def test_returns_gym_with_correct_fields(self, mock_db):
        coach = make_coach()
        coach_result = MagicMock()
        coach_result.scalar_one_or_none.return_value = coach

        gym_row = self._make_gym_row()
        gyms_result = MagicMock()
        gyms_result.all.return_value = [gym_row]

        # clients count
        clients_result = MagicMock()
        clients_result.scalar.return_value = 12

        # sessions for this gym
        sessions_result = MagicMock()
        sessions_result.scalars.return_value.all.return_value = []

        mock_db.execute.side_effect = [
            coach_result, gyms_result, clients_result, sessions_result
        ]

        result = await get_coach_active_gyms(1, mock_db)

        assert len(result) == 1
        gym = result[0]
        assert gym["gym_id"] == 100
        assert gym["name"] == "Test Gym"
        assert gym["address"] == "Cairo"
        assert gym["clients_count"] == 12
        assert gym["classes_count"] == 0
        assert gym["next_class"] is None

    async def test_returns_multiple_gyms(self, mock_db):
        coach = make_coach()
        coach_result = MagicMock()
        coach_result.scalar_one_or_none.return_value = coach

        rows = [self._make_gym_row(100, "FitZone"), self._make_gym_row(200, "Test Gym")]
        gyms_result = MagicMock()
        gyms_result.all.return_value = rows

        def make_clients_result(n):
            r = MagicMock()
            r.scalar.return_value = n
            return r

        def make_sessions_result(sessions):
            r = MagicMock()
            r.scalars.return_value.all.return_value = sessions
            return r

        mock_db.execute.side_effect = [
            coach_result,
            gyms_result,
            make_clients_result(5),
            make_sessions_result([]),
            make_clients_result(3),
            make_sessions_result([]),
        ]

        result = await get_coach_active_gyms(1, mock_db)

        assert len(result) == 2
        names = {g["name"] for g in result}
        assert names == {"FitZone", "Test Gym"}

    async def test_next_class_populated_from_recurring_session(self, mock_db):
        coach = make_coach()
        coach_result = MagicMock()
        coach_result.scalar_one_or_none.return_value = coach

        gym_row = self._make_gym_row()
        gyms_result = MagicMock()
        gyms_result.all.return_value = [gym_row]

        clients_result = MagicMock()
        clients_result.scalar.return_value = 0

        session = make_session(is_recurring=True, day_of_week="monday")
        sessions_result = MagicMock()
        sessions_result.scalars.return_value.all.return_value = [session]

        enrolled_result = MagicMock()
        enrolled_result.return_value = 2
        mock_db.scalar.return_value = 2

        mock_db.execute.side_effect = [
            coach_result, gyms_result, clients_result, sessions_result
        ]

        result = await get_coach_active_gyms(1, mock_db)

        assert result[0]["next_class"] is not None
        assert result[0]["classes_count"] == 1

    async def test_excludes_past_one_time_sessions_from_upcoming(self, mock_db):
        coach = make_coach()
        coach_result = MagicMock()
        coach_result.scalar_one_or_none.return_value = coach

        gym_row = self._make_gym_row()
        gyms_result = MagicMock()
        gyms_result.all.return_value = [gym_row]

        clients_result = MagicMock()
        clients_result.scalar.return_value = 0

        past_session = make_session(
            is_recurring=False,
            day_of_week=None,
            date=date.today() - timedelta(days=2),
        )
        sessions_result = MagicMock()
        sessions_result.scalars.return_value.all.return_value = [past_session]

        mock_db.execute.side_effect = [
            coach_result, gyms_result, clients_result, sessions_result
        ]
        mock_db.scalar.return_value = 0

        result = await get_coach_active_gyms(1, mock_db)

        assert result[0]["classes_count"] == 0
        assert result[0]["next_class"] is None



# ── get_coach_announcements ───────────────────────────────────────────────────

class TestGetCoachAnnouncements:

    def _make_gym_row(self, gym_id=100, gym_name="Test Gym"):
        row = MagicMock()
        row.gymID = gym_id
        row.gymName = gym_name
        return row

    async def test_returns_empty_list_when_no_gyms(self, mock_db):
        gyms_result = MagicMock()
        gyms_result.all.return_value = []
        mock_db.execute.side_effect = [gyms_result]

        result = await get_coach_announcements(1, mock_db)

        assert result == []

    async def test_returns_announcements_for_coach(self, mock_db):
        gym_row = self._make_gym_row()
        gyms_result = MagicMock()
        gyms_result.all.return_value = [gym_row]

        announcement = make_announcement(reciever="Coaches only")
        ann_result = MagicMock()
        ann_result.scalars.return_value.all.return_value = [announcement]

        mock_db.execute.side_effect = [gyms_result, ann_result]

        result = await get_coach_announcements(1, mock_db)

        assert len(result) == 1
        assert result[0]["title"] == announcement.title
        assert result[0]["gym_name"] == "Test Gym" 

    async def test_announcement_has_required_keys(self, mock_db):
        gym_row = self._make_gym_row()
        gyms_result = MagicMock()
        gyms_result.all.return_value = [gym_row]

        announcement = make_announcement()
        ann_result = MagicMock()
        ann_result.scalars.return_value.all.return_value = [announcement]
        mock_db.execute.side_effect = [gyms_result, ann_result]

        result = await get_coach_announcements(1, mock_db)

        required_keys = {"id", "gym_name", "title", "content", "created_at"}
        assert required_keys.issubset(result[0].keys())

    async def test_aggregates_announcements_across_multiple_gyms(self, mock_db):
        row1 = self._make_gym_row(100, "FitZone")
        row2 = self._make_gym_row(200, "Test Gym")
        gyms_result = MagicMock()
        gyms_result.all.return_value = [row1, row2]

        a1 = make_announcement(announce_id=1)
        a2 = make_announcement(announce_id=2)

        ann_result1 = MagicMock()
        ann_result1.scalars.return_value.all.return_value = [a1]
        ann_result2 = MagicMock()
        ann_result2.scalars.return_value.all.return_value = [a2]

        mock_db.execute.side_effect = [gyms_result, ann_result1, ann_result2]

        result = await get_coach_announcements(1, mock_db)

        assert len(result) == 2

    async def test_filters_by_gym_id_when_provided(self, mock_db):
        """When gym_id is passed, only that gym's announcements are returned."""
        gym_row = self._make_gym_row(100, "Test Gym")
        gyms_result = MagicMock()
        gyms_result.all.return_value = [gym_row]

        announcement = make_announcement()
        ann_result = MagicMock()
        ann_result.scalars.return_value.all.return_value = [announcement]
        mock_db.execute.side_effect = [gyms_result, ann_result]

        result = await get_coach_announcements(1, mock_db, gym_id=100)

        assert len(result) == 1

    async def test_results_sorted_by_created_at_descending(self, mock_db):
        gym_row = self._make_gym_row()
        gyms_result = MagicMock()
        gyms_result.all.return_value = [gym_row]

        a_old = make_announcement(announce_id=1)
        a_old.created_at.isoformat.return_value = "2025-01-01T10:00:00"
        a_new = make_announcement(announce_id=2)
        a_new.created_at.isoformat.return_value = "2025-06-01T10:00:00"

        ann_result = MagicMock()
        ann_result.scalars.return_value.all.return_value = [a_old, a_new]
        mock_db.execute.side_effect = [gyms_result, ann_result]

        result = await get_coach_announcements(1, mock_db)

        assert result[0]["created_at"] >= result[1]["created_at"]

    async def test_returns_empty_list_when_no_announcements(self, mock_db):
        gym_row = self._make_gym_row()
        gyms_result = MagicMock()
        gyms_result.all.return_value = [gym_row]

        ann_result = MagicMock()
        ann_result.scalars.return_value.all.return_value = []
        mock_db.execute.side_effect = [gyms_result, ann_result]

        result = await get_coach_announcements(1, mock_db)

        assert result == []