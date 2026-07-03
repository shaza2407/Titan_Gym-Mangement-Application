import pytest
from fastapi import HTTPException
from unittest.mock import MagicMock
from app.services.admin.admin_analytics_service import (
    _verify_gym_owner,
    calc_revenue_for_period,
    get_all_active_members,
    get_active_members_this_month,
    get_members_for_period,
    get_avg_attendance_for_period,
    get_active_classes_for_period,
    get_revenue_for_last_6_months,
    get_members_for_last_6_months,
    get_membership_distribution,
    get_offer_details_service,
)
from datetime import date, timedelta

from test.helpers import (
    scalar_one_or_none_result,
    scalar_one_result, all_result
)

GYM_ID = 5
USER_ID = 1


# _verify_gym_owner
class TestVerifyGymOwner:
    async def test_raises_404_if_admin_not_found(self, mock_db):
        mock_db.execute.return_value = scalar_one_or_none_result(None)
        with pytest.raises(HTTPException) as exc:
            await _verify_gym_owner(GYM_ID, USER_ID, mock_db)
        assert exc.value.status_code == 404

    async def test_raises_404_if_gym_not_found(self, mock_db, mock_admin):
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(mock_admin),
            scalar_one_or_none_result(None),
        ]

        with pytest.raises(HTTPException) as exc:
            await _verify_gym_owner(GYM_ID, USER_ID, mock_db)
        assert exc.value.status_code == 404

    async def test_returns_gym_if_owner(self, mock_db, mock_admin, mock_gym):
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(mock_admin),
            scalar_one_or_none_result(mock_gym),
        ]

        result = await _verify_gym_owner(GYM_ID, USER_ID, mock_db)
        assert result == mock_gym


# calc_revenue_for_period
class TestCalcRevenueForPeriod:
    async def test_returns_revenue(self, mock_db, mock_gym):
        mock_db.execute.return_value = scalar_one_result(5000)

        result = await calc_revenue_for_period(mock_db, mock_gym, date.today(), date.today())
        assert result == 5000

    async def test_returns_zero_when_no_subscriptions(self, mock_db, mock_gym):
        mock_db.execute.return_value = scalar_one_result(None)
        result = await calc_revenue_for_period(mock_db, mock_gym, date.today(), date.today())
        assert result == 0


# get_all_active_members
class TestGetAllActiveMembers:
    async def test_returns_active_member_count(self, mock_db):
        r = MagicMock()
        r.scalar_one_or_none.return_value = 42
        mock_db.execute.return_value = r

        result = await get_all_active_members(mock_db, GYM_ID)
        assert result == 42

    async def test_defaults_to_zero_when_none(self, mock_db):
        r = MagicMock()
        r.scalar_one_or_none.return_value = None
        mock_db.execute.return_value = r

        result = await get_all_active_members(mock_db, GYM_ID)
        assert result == 0


# get_active_members_this_month
class TestGetActiveMembersThisMonth:
    async def test_returns_count(self, mock_db, mock_gym):
        r = MagicMock()
        r.scalar_one_or_none.return_value = 15
        mock_db.execute.return_value = r

        result = await get_active_members_this_month(mock_db, mock_gym)
        assert result == 15

    async def test_defaults_to_zero(self, mock_db, mock_gym):
        r = MagicMock()
        r.scalar_one_or_none.return_value = None
        mock_db.execute.return_value = r

        result = await get_active_members_this_month(mock_db, mock_gym)
        assert result == 0


# get_members_for_period
class TestGetMembersForPeriod:

    async def test_returns_count_for_period(self, mock_db, mock_gym):
        r = MagicMock()
        r.scalar_one_or_none.return_value = 10
        mock_db.execute.return_value = r

        start = date.today() - timedelta(days=30)
        result = await get_members_for_period(mock_db, mock_gym, start, date.today())
        assert result == 10

    async def test_returns_zero_when_none(self, mock_db, mock_gym):
        r = MagicMock()
        r.scalar_one_or_none.return_value = None
        mock_db.execute.return_value = r

        result = await get_members_for_period(mock_db, mock_gym, date.today(), date.today())
        assert result == 0


# get_avg_attendance_for_period
class TestGetAvgAttendanceForPeriod:

    async def test_returns_average(self, mock_db, mock_gym):
        r = MagicMock()
        r.scalar_one.return_value = 70
        mock_db.execute.return_value = r

        start = date.today() - timedelta(days=6)
        result = await get_avg_attendance_for_period(mock_db, mock_gym, start, date.today())
        assert result == 10  # 70 / 7 days

    async def test_returns_zero_when_no_checkins(self, mock_db, mock_gym):
        r = MagicMock()
        r.scalar_one.return_value = None
        mock_db.execute.return_value = r

        start = date.today() - timedelta(days=6)
        result = await get_avg_attendance_for_period(mock_db, mock_gym, start, date.today())

        assert result == 0


# get_active_classes_for_period
class TestGetActiveClassesForPeriod:
    async def test_returns_class_count(self, mock_db, mock_gym):
        r = MagicMock()
        r.scalar_one_or_none.return_value = 8
        mock_db.execute.return_value = r

        result = await get_active_classes_for_period(mock_db, mock_gym, date.today(), date.today())
        assert result == 8

    async def test_returns_zero_when_none(self, mock_db, mock_gym):
        r = MagicMock()
        r.scalar_one_or_none.return_value = None
        mock_db.execute.return_value = r

        result = await get_active_classes_for_period(mock_db, mock_gym, date.today(), date.today())
        assert result == 0


# get_revenue_for_last_6_months
class TestGetRevenueForLast7Months:
    async def test_returns_7_months(self, mock_db, mock_gym):
        r = MagicMock()
        r.scalar_one.return_value = 1000
        mock_db.execute.return_value = r

        result = await get_revenue_for_last_6_months(mock_db, mock_gym)
        assert len(result.months) == 6

    async def test_months_have_correct_keys(self, mock_db, mock_gym):
        r = MagicMock()
        r.scalar_one.return_value = 500
        mock_db.execute.return_value = r

        result = await get_revenue_for_last_6_months(mock_db, mock_gym)
        for m in result.months:
            assert m.month is not None
            assert m.revenue is not None


# get_members_for_last_6_months
class TestGetMembersForLast6Months:
    async def test_returns_7_months(self, mock_db, mock_gym):
        r = MagicMock()
        r.scalar_one_or_none.return_value = 5
        mock_db.execute.return_value = r

        result = await get_members_for_last_6_months(mock_db, mock_gym)

        assert len(result.months) == 6

    async def test_months_have_correct_keys(self, mock_db, mock_gym):
        r = MagicMock()
        r.scalar_one_or_none.return_value = 0
        mock_db.execute.return_value = r

        result = await get_members_for_last_6_months(mock_db, mock_gym)

        for m in result.months:
            assert m.month is not None
            assert m.total_members is not None


# get_membership_distribution
class TestGetMembershipDistribution:
    async def test_returns_distribution(self, mock_db, mock_gym):
        row = MagicMock()
        row.type = "monthly"
        row.count = 20
        mock_db.execute.return_value = all_result([row])

        result = await get_membership_distribution(mock_db, mock_gym)

        assert len(result.distribution) == 1
        assert result.distribution[0].type == "monthly"
        assert result.distribution[0].count == 20

    async def test_returns_empty_when_no_members(self, mock_db, mock_gym):
        mock_db.execute.return_value = all_result([])
        result = await get_membership_distribution(mock_db, mock_gym)
        assert result.distribution == []


# get_offer_details
class TestGetOfferDetails:
    async def test_raises_404_if_offer_not_found(self, mock_db, mock_gym):
        mock_db.execute.return_value = scalar_one_or_none_result(None)

        with pytest.raises(HTTPException) as exc:
            await get_offer_details_service(mock_db, mock_gym, offer_id=1)
        assert exc.value.status_code == 404

    async def test_recipients_is_empty_when_none(self, mock_db, mock_gym):
        offer = MagicMock()
        offer.id = 1
        offer.title = "Offer"
        offer.offer_type = "discount"
        offer.description = "desc"
        offer.benefit = "5%"
        offer.valid_until = None
        offer.target_type = "all_members"
        offer.number_of_members = 0
        offer.created_at = None

        mock_db.execute.side_effect = [
            scalar_one_or_none_result(offer),
            all_result([]),
        ]

        result = await get_offer_details_service(mock_db, mock_gym, offer_id=1)

        assert result["recipients"] == []