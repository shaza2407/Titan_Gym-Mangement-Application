# test/unit/client/test_client_gym_info_service.py
#
# Run with:
#   pytest test/unit/client/test_client_gym_info_service.py -v

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import date, timedelta
from fastapi import HTTPException

from app.services.client.client_gym_info import (
    fetch_client_gym,
    fetch_gym_announcements,
    fetch_weekly_schedule,
)
from app.services.admin.admin_schedule import DAY_NAMES
from app.models.Gym import Gym
from app.models.announcement import Announcement


# ── Helpers ───────────────────────────────────────────────────────────────────

def _make_gym(gym_id: int = 1, name: str = "Titan Gym") -> MagicMock:
    g = MagicMock(spec=Gym)
    g.gymID = gym_id
    g.gymName = name
    return g


def _make_announcement(gym_id: int = 1, receiver: str = "Clients only") -> MagicMock:
    a = MagicMock(spec=Announcement)
    a.gymID = gym_id
    a.reciever = receiver
    return a


def _make_class(day_of_week: str, start_time: str, title: str = "Yoga") -> dict:
    return {
        "id": 1,
        "title": title,
        "day_of_week": day_of_week,
        "start_time": start_time,
        "duration": 60,
        "is_recurring": True,
        "gymID": 1,
        "coach_id": 1,
        "coach_name": "Coach A",
        "current_clients": 5,
        "max_clients": 20,
        "date": None,
    }


def _db_with_scalars_all(rows: list) -> AsyncMock:
    result_mock = MagicMock()
    result_mock.scalars.return_value.all.return_value = rows
    db = AsyncMock()
    db.execute = AsyncMock(return_value=result_mock)
    return db


# ════════════════════════════════════════════════════════════════════════════
# fetch_client_gym
# ════════════════════════════════════════════════════════════════════════════

class TestFetchClientGym:

    async def test_returns_gym_from_helper(self):
        gym = _make_gym(gym_id=1)

        with patch(
            "app.services.client.client_gym_info.get_client_gym_or_404",
            new=AsyncMock(return_value=gym),
        ):
            result = await fetch_client_gym(clientID=1, db=AsyncMock())

        assert result is gym

    async def test_raises_404_when_no_membership(self):
        with patch(
            "app.services.client.client_gym_info.get_client_gym_or_404",
            new=AsyncMock(side_effect=HTTPException(status_code=404, detail="No gym membership found for this client.")),
        ):
            with pytest.raises(HTTPException) as exc:
                await fetch_client_gym(clientID=99, db=AsyncMock())

        assert exc.value.status_code == 404

    async def test_passes_correct_client_id(self):
        gym = _make_gym()
        mock_helper = AsyncMock(return_value=gym)

        with patch(
            "app.services.client.client_gym_info.get_client_gym_or_404",
            new=mock_helper,
        ):
            await fetch_client_gym(clientID=42, db=AsyncMock())

        mock_helper.assert_awaited_once()
        assert mock_helper.call_args[0][0] == 42


# ════════════════════════════════════════════════════════════════════════════
# fetch_gym_announcements
# ════════════════════════════════════════════════════════════════════════════

class TestFetchGymAnnouncements:

    async def test_returns_announcements_list(self):
        gym = _make_gym(gym_id=1)
        announcements = [
            _make_announcement(receiver="Clients only"),
            _make_announcement(receiver="Clients and Coaches"),
        ]
        db = _db_with_scalars_all(announcements)

        with patch(
            "app.services.client.client_gym_info.get_client_gym_or_404",
            new=AsyncMock(return_value=gym),
        ):
            result = await fetch_gym_announcements(clientID=1, db=db)

        assert len(result) == 2

    async def test_returns_empty_list_when_no_announcements(self):
        gym = _make_gym()
        db = _db_with_scalars_all([])

        with patch(
            "app.services.client.client_gym_info.get_client_gym_or_404",
            new=AsyncMock(return_value=gym),
        ):
            result = await fetch_gym_announcements(clientID=1, db=db)

        assert result == []

    async def test_raises_404_when_no_membership(self):
        with patch(
            "app.services.client.client_gym_info.get_client_gym_or_404",
            new=AsyncMock(side_effect=HTTPException(status_code=404, detail="No gym membership found for this client.")),
        ):
            with pytest.raises(HTTPException) as exc:
                await fetch_gym_announcements(clientID=99, db=AsyncMock())

        assert exc.value.status_code == 404

    async def test_queries_db_for_announcements(self):
        gym = _make_gym()
        db = _db_with_scalars_all([])

        with patch(
            "app.services.client.client_gym_info.get_client_gym_or_404",
            new=AsyncMock(return_value=gym),
        ):
            await fetch_gym_announcements(clientID=1, db=db)

        db.execute.assert_awaited_once()


# ════════════════════════════════════════════════════════════════════════════
# fetch_weekly_schedule
# ════════════════════════════════════════════════════════════════════════════

class TestFetchWeeklySchedule:

    async def test_returns_dict_with_all_seven_days(self):
        gym = _make_gym()

        with patch(
            "app.services.client.client_gym_info.get_client_gym_or_404",
            new=AsyncMock(return_value=gym),
        ), patch(
            "app.services.client.client_gym_info.get_all_classes",
            new=AsyncMock(return_value=[]),
        ):
            result = await fetch_weekly_schedule(clientID=1, db=AsyncMock())

        assert set(result.keys()) == set(DAY_NAMES)

    async def test_empty_schedule_all_days_have_empty_lists(self):
        gym = _make_gym()

        with patch(
            "app.services.client.client_gym_info.get_client_gym_or_404",
            new=AsyncMock(return_value=gym),
        ), patch(
            "app.services.client.client_gym_info.get_all_classes",
            new=AsyncMock(return_value=[]),
        ):
            result = await fetch_weekly_schedule(clientID=1, db=AsyncMock())

        for day in DAY_NAMES:
            assert result[day] == []

    async def test_classes_grouped_by_day_of_week(self):
        gym = _make_gym()
        classes = [
            _make_class("monday", "09:00", "Yoga"),
            _make_class("monday", "11:00", "Pilates"),
            _make_class("wednesday", "10:00", "Spin"),
        ]

        with patch(
            "app.services.client.client_gym_info.get_client_gym_or_404",
            new=AsyncMock(return_value=gym),
        ), patch(
            "app.services.client.client_gym_info.get_all_classes",
            new=AsyncMock(return_value=classes),
        ):
            result = await fetch_weekly_schedule(clientID=1, db=AsyncMock())

        assert len(result["monday"]) == 2
        assert len(result["wednesday"]) == 1
        assert len(result["tuesday"]) == 0

    async def test_classes_sorted_by_start_time_within_day(self):
        gym = _make_gym()
        # Intentionally out of order
        classes = [
            _make_class("monday", "14:00", "Boxing"),
            _make_class("monday", "08:00", "Yoga"),
            _make_class("monday", "11:00", "Pilates"),
        ]

        with patch(
            "app.services.client.client_gym_info.get_client_gym_or_404",
            new=AsyncMock(return_value=gym),
        ), patch(
            "app.services.client.client_gym_info.get_all_classes",
            new=AsyncMock(return_value=classes),
        ):
            result = await fetch_weekly_schedule(clientID=1, db=AsyncMock())

        monday = result["monday"]
        assert monday[0]["start_time"] == "08:00"
        assert monday[1]["start_time"] == "11:00"
        assert monday[2]["start_time"] == "14:00"

    async def test_unknown_day_key_is_ignored(self):
        gym = _make_gym()
        classes = [
            _make_class("monday", "09:00"),
            _make_class("invalid_day", "10:00"),  # should be silently ignored
        ]

        with patch(
            "app.services.client.client_gym_info.get_client_gym_or_404",
            new=AsyncMock(return_value=gym),
        ), patch(
            "app.services.client.client_gym_info.get_all_classes",
            new=AsyncMock(return_value=classes),
        ):
            result = await fetch_weekly_schedule(clientID=1, db=AsyncMock())

        assert "invalid_day" not in result
        assert len(result["monday"]) == 1

    async def test_passes_correct_week_range_to_get_all_classes(self):
        gym = _make_gym()
        mock_get_all = AsyncMock(return_value=[])

        today = date.today()
        expected_week_start = today - timedelta(days=today.weekday())
        expected_week_end = expected_week_start + timedelta(days=6)

        with patch(
            "app.services.client.client_gym_info.get_client_gym_or_404",
            new=AsyncMock(return_value=gym),
        ), patch(
            "app.services.client.client_gym_info.get_all_classes",
            new=mock_get_all,
        ):
            await fetch_weekly_schedule(clientID=1, db=AsyncMock())

        call_kwargs = mock_get_all.call_args.kwargs
        assert call_kwargs["week_start"] == expected_week_start
        assert call_kwargs["week_end"] == expected_week_end

    async def test_passes_gym_id_to_get_all_classes(self):
        gym = _make_gym(gym_id=99)
        mock_get_all = AsyncMock(return_value=[])

        with patch(
            "app.services.client.client_gym_info.get_client_gym_or_404",
            new=AsyncMock(return_value=gym),
        ), patch(
            "app.services.client.client_gym_info.get_all_classes",
            new=mock_get_all,
        ):
            await fetch_weekly_schedule(clientID=1, db=AsyncMock())

        assert mock_get_all.call_args.kwargs["gymID"] == 99

    async def test_raises_404_when_no_membership(self):
        with patch(
            "app.services.client.client_gym_info.get_client_gym_or_404",
            new=AsyncMock(side_effect=HTTPException(status_code=404, detail="No gym membership found for this client.")),
        ):
            with pytest.raises(HTTPException) as exc:
                await fetch_weekly_schedule(clientID=99, db=AsyncMock())

        assert exc.value.status_code == 404

    async def test_all_seven_days_populated_correctly(self):
        gym = _make_gym()
        classes = [_make_class(day, "09:00") for day in DAY_NAMES]

        with patch(
            "app.services.client.client_gym_info.get_client_gym_or_404",
            new=AsyncMock(return_value=gym),
        ), patch(
            "app.services.client.client_gym_info.get_all_classes",
            new=AsyncMock(return_value=classes),
        ):
            result = await fetch_weekly_schedule(clientID=1, db=AsyncMock())

        for day in DAY_NAMES:
            assert len(result[day]) == 1