from unittest.mock import MagicMock, patch
from datetime import datetime, timedelta, date
from app.routers.Admin.churn import (
    encode_days,
    get_weekly_attendance,
    get_days_since_last_visit,
    get_days_until_expiry,
    predict_churn_risk,
)

CLIENT_ID = 1
GYM_ID = 5


# encode_days
class TestEncodeDays:
    def test_zero_days_is_zero(self):
        assert encode_days(0) == 0
    def test_one_day_is_zero(self):
        assert encode_days(1) == 0
    def test_two_days_is_one(self):
        assert encode_days(2) == 1
    def test_four_days_is_one(self):
        assert encode_days(4) == 1
    def test_five_days_is_two(self):
        assert encode_days(5) == 2
    def test_seven_days_is_two(self):
        assert encode_days(7) == 2


# get_days_until_expiry
class TestGetDaysUntilExpiry:

    def test_returns_days_remaining(self):
        membership = MagicMock()
        membership.subscription_end = date.today() + timedelta(days=10)
        assert get_days_until_expiry(membership) == 10 #inclusive count(iclude today)

    def test_returns_zero_if_expired(self):
        membership = MagicMock()
        membership.subscription_end = date.today() - timedelta(days=5)
        assert get_days_until_expiry(membership) == 0

    def test_returns_zero_on_expiry_day(self):
        membership = MagicMock()
        membership.subscription_end = date.today()
        assert get_days_until_expiry(membership) == 0 #include today


# get_weekly_attendance -> returns W0, W1, W2 ... and so on
class TestGetWeeklyAttendance:

    async def test_returns_12_weeks(self, mock_db):
        mock_db.execute.return_value = MagicMock(all=MagicMock(return_value=[]))
        result = await get_weekly_attendance(CLIENT_ID, GYM_ID, mock_db)
        assert len(result) == 12

    async def test_all_zeros_when_no_checkins(self, mock_db):
        mock_db.execute.return_value = MagicMock(all=MagicMock(return_value=[]))
        result = await get_weekly_attendance(CLIENT_ID, GYM_ID, mock_db)
        assert all(v == 0 for v in result)

    async def test_encodes_checkins_correctly(self, mock_db):
        now = datetime.now().replace(tzinfo=None)
        # Put 5 checkins in the most recent week (i=0 → week_start = now-7d, week_end = now)
        checkins = [(now - timedelta(days=1),)] * 5
        mock_db.execute.return_value = MagicMock(all=MagicMock(return_value=checkins))

        result = await get_weekly_attendance(CLIENT_ID, GYM_ID, mock_db)
        assert result[-1] == 2

    async def test_values_are_0_1_or_2(self, mock_db):
        mock_db.execute.return_value = MagicMock(all=MagicMock(return_value=[]))
        result = await get_weekly_attendance(CLIENT_ID, GYM_ID, mock_db)
        assert all(v in (0, 1, 2) for v in result)


# get_days_since_last_visit
class TestGetDaysSinceLastVisit:

    async def test_returns_365_if_never_visited(self, mock_db):
        mock_db.execute.return_value = MagicMock(first=MagicMock(return_value=None))
        result = await get_days_since_last_visit(CLIENT_ID, GYM_ID, mock_db)
        assert result == 365

    async def test_returns_correct_days(self, mock_db):
        last_checkin = datetime.now().replace(tzinfo=None) - timedelta(days=7)
        row = MagicMock()
        row.checked_in = last_checkin
        mock_db.execute.return_value = MagicMock(first=MagicMock(return_value=row))

        result = await get_days_since_last_visit(CLIENT_ID, GYM_ID, mock_db)

        assert result == 7


# predict_churn_risk
class TestPredictChurnRisk:

    async def test_returns_valid_risk_label(self, mock_db):
        membership = MagicMock()
        membership.clientID = CLIENT_ID
        membership.gymID = GYM_ID
        membership.subscription_end = date.today() + timedelta(days=10)

        mock_db.execute.return_value = MagicMock(all=MagicMock(return_value=[]))
        mock_db.execute.return_value.first = MagicMock(return_value=None)

        with patch("app.routers.Admin.churn.predict", return_value="High"):
            result = await predict_churn_risk(membership, mock_db)

        assert result in ("High", "Mid", "Low")

    async def test_returns_error_string_on_predict_failure(self, mock_db):
        membership = MagicMock()
        membership.clientID = CLIENT_ID
        membership.gymID = GYM_ID
        membership.subscription_end = date.today() + timedelta(days=10)

        mock_db.execute.return_value = MagicMock(all=MagicMock(return_value=[]))
        mock_db.execute.return_value.first = MagicMock(return_value=None)

        with patch("app.routers.Admin.churn.predict", side_effect=Exception("model error")):
            result = await predict_churn_risk(membership, mock_db)

        assert result.startswith("Error")