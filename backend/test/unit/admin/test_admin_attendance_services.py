from unittest.mock import MagicMock
from app.services.admin.admin_attendance_service import (
    get_attendance_statistics,
    get_weekly_attendance_chart,
)
from test.helpers import (
    scalar_one_or_none_result,
)


GYM_ID = 5


# get_attendance_statistics
class TestGetAttendanceStatistics:

    async def test_returns_today_and_week_totals(self, mock_db, mock_gym):
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(20),   # today total
            scalar_one_or_none_result(80),   # week total
        ]

        result = await get_attendance_statistics(mock_db, mock_gym)

        assert result.today_total == 20
        assert result.this_week == 80

    async def test_defaults_to_zero_when_no_data(self, mock_db, mock_gym):
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(None),
            scalar_one_or_none_result(None),
        ]

        result = await get_attendance_statistics(mock_db, mock_gym)
        assert result.today_total == 0
        assert result.this_week == 0

    async def test_week_total_includes_today(self, mock_db, mock_gym):
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(5),
            scalar_one_or_none_result(35),
        ]

        result = await get_attendance_statistics(mock_db, mock_gym)

        assert result.this_week >= result.today_total


# get_weekly_attendance_chart
class TestGetWeeklyAttendanceChart:
    async def test_returns_7_days(self, mock_db, mock_gym):
        mock_db.execute.return_value = MagicMock(all=MagicMock(return_value=[]))
        result = await get_weekly_attendance_chart(mock_db, mock_gym)

        assert len(result.days) == 7

    async def test_missing_days_default_to_zero(self, mock_db, mock_gym):
        mock_db.execute.return_value = MagicMock(all=MagicMock(return_value=[]))
        result = await get_weekly_attendance_chart(mock_db, mock_gym)

        assert all(d.count == 0 for d in result.days)

    async def test_maps_counts_to_correct_days(self, mock_db, mock_gym):
        from datetime import date, timedelta
        today = date.today()
        week_start = today - timedelta(days=6)

        # Simulate one row returned: day=week_start, count=10
        row = MagicMock()
        row.day = week_start
        row.count = 10
        mock_db.execute.return_value = MagicMock(all=MagicMock(return_value=[row]))

        result = await get_weekly_attendance_chart(mock_db, mock_gym)

        assert result.days[0].count == 10

    async def test_week_start_is_correct(self, mock_db, mock_gym):
        from datetime import date, timedelta
        mock_db.execute.return_value = MagicMock(all=MagicMock(return_value=[]))

        result = await get_weekly_attendance_chart(mock_db, mock_gym)

        expected_start = str(date.today() - timedelta(days=6))
        assert result.week_start == expected_start