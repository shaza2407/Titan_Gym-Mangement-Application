# tests/unit/coach/test_coach_dashboard.py
import pytest
from datetime import date, time, timedelta
from unittest.mock import MagicMock

from test.unit.coach.helpers import (
    make_session,
    mock_execute_scalars,
)
from app.services.coach.coach_dashboard import (
    get_coach_dashboard_stats,
    get_upcoming_classes,
)


# ── get_coach_dashboard_stats ─────────────────────────────────────────────────

class TestGetCoachDashboardStats:

    async def _setup_sessions(self, mock_db, sessions, total_clients=0, active_gyms=0):
        
        # sessions query
        sessions_result = MagicMock()
        sessions_result.scalars.return_value.all.return_value = sessions

        # total_clients query
        clients_result = MagicMock()
        clients_result.scalar.return_value = total_clients

        # active_gyms query
        gyms_result = MagicMock()
        gyms_result.scalar.return_value = active_gyms

        mock_db.execute.side_effect = [sessions_result, clients_result, gyms_result]

    async def test_returns_zero_stats_with_no_sessions(self, mock_db):
        await self._setup_sessions(mock_db, [])

        stats = await get_coach_dashboard_stats(10, mock_db)

        assert stats["weekly_classes"] == 0
        assert stats["total_clients"] == 0
        assert stats["active_gyms"] == 0

    async def test_counts_recurring_session_in_7_day_window(self, mock_db):
        from datetime import date as dt
        day_names = ["monday", "tuesday", "wednesday",
                     "thursday", "friday", "saturday", "sunday"]
        today_name = day_names[dt.today().weekday()]

        session = make_session(is_recurring=True, day_of_week=today_name)
        await self._setup_sessions(mock_db, [session], total_clients=5, active_gyms=1)

        stats = await get_coach_dashboard_stats(10, mock_db)

        assert stats["weekly_classes"] == 1

    async def test_counts_one_time_session_in_7_day_window(self, mock_db):
        session = make_session(
            is_recurring=False, day_of_week=None, date=date.today() + timedelta(days=2)
        )
        await self._setup_sessions(mock_db, [session])

        stats = await get_coach_dashboard_stats(10, mock_db)

        assert stats["weekly_classes"] == 1

    async def test_excludes_one_time_session_beyond_7_days(self, mock_db):
        session = make_session(
            is_recurring=False, day_of_week=None, date=date.today() + timedelta(days=8)
        )
        await self._setup_sessions(mock_db, [session])

        stats = await get_coach_dashboard_stats(10, mock_db)

        assert stats["weekly_classes"] == 0


    async def test_total_clients_defaults_to_zero_on_none(self, mock_db):
        sessions_result = MagicMock()
        sessions_result.scalars.return_value.all.return_value = []
        clients_result = MagicMock()
        clients_result.scalar.return_value = None  
        gyms_result = MagicMock()
        gyms_result.scalar.return_value = None
        mock_db.execute.side_effect = [sessions_result, clients_result, gyms_result]

        stats = await get_coach_dashboard_stats(10, mock_db)

        assert stats["total_clients"] == 0
        assert stats["active_gyms"] == 0




# ── get_upcoming_classes ──────────────────────────────────────────────────────

class TestGetUpcomingClasses:
    day_names = ["monday", "tuesday", "wednesday",
                "thursday", "friday", "saturday", "sunday"]


    async def _make_db_for_upcoming(self, mock_db, sessions, gym_name="FitZone", enrolled=2):
        sessions_result = MagicMock()
        sessions_result.scalars.return_value.all.return_value = sessions

        gym_name_result = MagicMock()
        gym_name_result.scalar_one_or_none.return_value = gym_name

        # _count_enrolled uses db.scalar
        mock_db.scalar.return_value = enrolled

        # First execute = sessions, subsequent = gym name lookups
        side_effects = [sessions_result] + [gym_name_result] * len(sessions)
        mock_db.execute.side_effect = side_effects

    async def test_returns_todays_recurring_class(self, mock_db):
        today_name = self.day_names[date.today().weekday()]

        session = make_session(is_recurring=True, day_of_week=today_name)
        await self._make_db_for_upcoming(mock_db, [session])

        classes = await get_upcoming_classes(10, mock_db)

        assert len(classes) == 1
        assert classes[0]["title"] == "Morning Yoga"

    async def test_returns_todays_one_time_class(self, mock_db):
        session = make_session(is_recurring=False, day_of_week=None, date=date.today())
        await self._make_db_for_upcoming(mock_db, [session])

        classes = await get_upcoming_classes(10, mock_db)

        assert len(classes) == 1

    async def test_excludes_recurring_session_not_today(self, mock_db):
        # Pick a day that is NOT today
        tomorrow_name = self.day_names[(date.today().weekday() + 1) % 7]
        session = make_session(is_recurring=True, day_of_week=tomorrow_name)

        sessions_result = MagicMock()
        sessions_result.scalars.return_value.all.return_value = [session]
        mock_db.execute.side_effect = [sessions_result, MagicMock()]

        classes = await get_upcoming_classes(10, mock_db)

        assert classes == []

    async def test_respects_limit(self, mock_db):
        from datetime import date as dt
        day_names = ["monday", "tuesday", "wednesday",
                     "thursday", "friday", "saturday", "sunday"]
        today_name = self.day_names[dt.today().weekday()]

        sessions = [
            make_session(id=i, is_recurring=True, day_of_week=today_name, start_time=time(8 + i, 0))
            for i in range(5)
        ]
        await self._make_db_for_upcoming(mock_db, sessions)

        classes = await get_upcoming_classes(10, mock_db, limit=3)

        assert len(classes) == 3

    async def test_classes_sorted_by_start_time(self, mock_db):
        from datetime import date as dt
        day_names = ["monday", "tuesday", "wednesday",
                     "thursday", "friday", "saturday", "sunday"]
        today_name = self.day_names[dt.today().weekday()]

        s1 = make_session(id=1, is_recurring=True, day_of_week=today_name, start_time=time(15, 0))
        s2 = make_session(id=2, is_recurring=True, day_of_week=today_name, start_time=time(7, 0))
        await self._make_db_for_upcoming(mock_db, [s1, s2])

        classes = await get_upcoming_classes(10, mock_db, limit=10)

        assert classes[0]["start_time"] <= classes[1]["start_time"]

    async def test_each_entry_has_required_keys(self, mock_db):
        from datetime import date as dt
        day_names = ["monday", "tuesday", "wednesday",
                     "thursday", "friday", "saturday", "sunday"]
        today_name = self.day_names[dt.today().weekday()]

        session = make_session(is_recurring=True, day_of_week=today_name)
        await self._make_db_for_upcoming(mock_db, [session])

        classes = await get_upcoming_classes(10, mock_db)

        required_keys = {
            "id", "title", "day_of_week", "date", "start_time",
            "duration", "gym_name", "current_clients", "max_clients",
        }
        assert required_keys.issubset(classes[0].keys())


    async def test_returns_empty_list_with_no_sessions(self, mock_db):
        mock_execute_scalars(mock_db, [])

        classes = await get_upcoming_classes(10, mock_db)

        assert classes == []