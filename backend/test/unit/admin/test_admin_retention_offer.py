# test/unit/admin/test_admin_retention_offer.py
import pytest
from fastapi import HTTPException
from unittest.mock import MagicMock, AsyncMock, patch
from datetime import date, timedelta, datetime, timezone
from app.services.admin.admin_retention_offer import (
    get_active_members,
    get_retention_dashboard_service,
    preview_members_service,
    create_and_send_offer_service,
)

GYM_ID = 5


def scalars_all_result(values):
    r = MagicMock()
    r.scalars.return_value.all.return_value = values
    return r


def scalar_one_or_none_result(value):
    r = MagicMock()
    r.scalar_one_or_none.return_value = value
    return r


def scalars_first_result(value):
    r = MagicMock()
    r.scalars.return_value.first.return_value = value
    return r


def make_membership(client_id=1, gym_id=GYM_ID, sub_end=None):
    m = MagicMock()
    m.id = 1
    m.clientID = client_id
    m.gymID = gym_id
    m.subscription_end = sub_end or (date.today() + timedelta(days=30))
    return m


# get_active_members
class TestGetActiveMembers:

    async def test_returns_active_members(self, mock_db):
        members = [make_membership(), make_membership(client_id=2)]
        mock_db.execute.return_value = scalars_all_result(members)
        result = await get_active_members(mock_db, GYM_ID)
        assert len(result) == 2

    async def test_returns_empty_list_when_none(self, mock_db):
        mock_db.execute.return_value = scalars_all_result([])
        result = await get_active_members(mock_db, GYM_ID)
        assert result == []


# get_retention_dashboard_service
class TestGetRetentionDashboardService:
    async def test_returns_dashboard_with_no_high_risk(self, mock_db):
        mock_db.execute.side_effect = [
            scalars_all_result([]),   # no active members
            scalars_all_result([]),   # no offers
        ]

        with patch("app.services.admin.admin_retention_offer.predict_churn_risk", new_callable=AsyncMock) as mock_predict:
            mock_predict.return_value = "Low"
            result = await get_retention_dashboard_service(mock_db, GYM_ID)

        assert result.high_risk_count == 0
        assert "No members are at high churn risk" in result.ai_insight

    async def test_returns_dashboard_with_high_risk(self, mock_db):
        member = make_membership()

        mock_db.execute.side_effect = [
            scalars_all_result([member]),
            scalars_all_result([]),
        ]

        with patch("app.services.admin.admin_retention_offer.predict_churn_risk", new_callable=AsyncMock) as mock_predict:
            mock_predict.return_value = "High"
            result = await get_retention_dashboard_service(mock_db, GYM_ID)

        assert result.high_risk_count == 1
        assert "high risk" in result.ai_insight

    async def test_offer_history_populated(self, mock_db):
        offer = MagicMock()
        offer.id = 1
        offer.title = "Test Offer"
        offer.offer_type = "discount"
        offer.target_type = "all_members"
        offer.number_of_members = 3
        offer.created_at = datetime(2024, 6, 1)

        mock_db.execute.side_effect = [
            scalars_all_result([]),
            scalars_all_result([offer]),
        ]

        with patch("app.services.admin.admin_retention_offer.predict_churn_risk", new_callable=AsyncMock):
            result = await get_retention_dashboard_service(mock_db, GYM_ID)

        assert len(result.offer_history) == 1
        assert result.offer_history[0].title == "Test Offer"

    async def test_total_active_members_count(self, mock_db):
        members = [make_membership(), make_membership(client_id=2)]
        mock_db.execute.side_effect = [
            scalars_all_result(members),
            scalars_all_result([]),
        ]

        with patch("app.services.admin.admin_retention_offer.predict_churn_risk", new_callable=AsyncMock) as mock_predict:
            mock_predict.return_value = "Low"
            result = await get_retention_dashboard_service(mock_db, GYM_ID)

        assert result.total_active_members == 2


# preview_members_service
class TestPreviewMembersService:
    async def test_skips_invalid_risk_levels(self, mock_db):
        member = make_membership()
        mock_db.execute.return_value = scalars_all_result([member])

        request = MagicMock()
        request.target_type = "highest_risk"
        request.number_of_members = 5

        with patch("app.services.admin.admin_retention_offer.predict_churn_risk", new_callable=AsyncMock) as mock_predict:
            mock_predict.return_value = "Error: something"
            result = await preview_members_service(mock_db, GYM_ID, request)

        assert result == []

    async def test_limits_results_by_number_of_members(self, mock_db):
        members = [make_membership(client_id=i) for i in range(5)]
        ## If I have 5 clients in the GYM but want the offer to be for 2 of them
        clients = []
        for i in range(5):
            c = MagicMock()
            c.clientID = i
            clients.append(c)

        users = []
        for i in range(5):
            u = MagicMock()
            u.name = f"User{i}"
            u.email = f"u{i}@x.com"
            users.append(u)

        side_effects = [scalars_all_result(members)]
        for c, u in zip(clients, users):
            side_effects.append(scalar_one_or_none_result(c))
            side_effects.append(scalar_one_or_none_result(u))
        mock_db.execute.side_effect = side_effects

        request = MagicMock()
        request.target_type = "highest_risk"
        request.number_of_members = 2

        with patch("app.services.admin.admin_retention_offer.predict_churn_risk", new_callable=AsyncMock) as mock_predict:
            mock_predict.return_value = "High"
            result = await preview_members_service(mock_db, GYM_ID, request)

        assert len(result) == 2

    async def test_returns_all_for_manual_selection(self, mock_db):
        member = make_membership()

        client = MagicMock()
        client.clientID = 1

        user = MagicMock()
        user.name = "Jane"
        user.email = "jane@x.com"

        mock_db.execute.side_effect = [
            scalars_all_result([member]),
            scalar_one_or_none_result(client),
            scalar_one_or_none_result(user),
        ]

        request = MagicMock()
        request.target_type = "manual_selection"
        request.number_of_members = None

        with patch("app.services.admin.admin_retention_offer.predict_churn_risk", new_callable=AsyncMock) as mock_predict:
            mock_predict.return_value = "Mid"
            result = await preview_members_service(mock_db, GYM_ID, request)

        assert len(result) == 1


# create_and_send_offer_service
class TestCreateAndSendOfferService:
    async def test_raises_400_if_no_members_selected(self, mock_db):
        request = MagicMock()
        request.selected_member_ids = []

        with pytest.raises(HTTPException) as exc:
            await create_and_send_offer_service(mock_db, GYM_ID, request)
        assert exc.value.status_code == 400

    async def test_creates_offer_and_recipients(self, mock_db):
        membership = make_membership()
        mock_db.flush = AsyncMock()
        mock_db.refresh = AsyncMock()
        mock_db.execute.return_value = scalar_one_or_none_result(membership)

        offer_obj = MagicMock()
        offer_obj.id = 1

        request = MagicMock()
        request.selected_member_ids = [1]
        request.title = "Test Offer"
        request.offer_type = "discount"
        request.description = "desc"
        request.benefit = "10%"
        request.valid_until = None
        request.target_type = "highest_risk"

        with patch("app.services.admin.admin_retention_offer.predict_churn_risk", new_callable=AsyncMock) as mock_predict:
            mock_predict.return_value = "High"
            result = await create_and_send_offer_service(mock_db, GYM_ID, request)

        mock_db.commit.assert_called_once()
        assert result["sent_to"] == 1

    async def test_returns_correct_offer_id(self, mock_db):
        membership = make_membership()
        mock_db.flush = AsyncMock()

        created_offer = MagicMock()
        created_offer.id = 42
        mock_db.refresh = AsyncMock()

        mock_db.execute.return_value = scalar_one_or_none_result(membership)

        request = MagicMock()
        request.selected_member_ids = [1]
        request.title = "Special Offer"
        request.offer_type = "free_month"
        request.description = "desc"
        request.benefit = "1 month free"
        request.valid_until = None
        request.target_type = "all_members"

        with patch("app.services.admin.admin_retention_offer.predict_churn_risk", new_callable=AsyncMock) as mock_predict:
            mock_predict.return_value = "Mid"
            result = await create_and_send_offer_service(mock_db, GYM_ID, request)

        assert "offer_id" in result
        assert "message" in result

    async def test_adds_one_recipient_per_member(self, mock_db):
        memberships = [make_membership(client_id=i) for i in range(3)]
        mock_db.flush = AsyncMock()
        mock_db.refresh = AsyncMock()

        execute_results = [scalar_one_or_none_result(m) for m in memberships]
        mock_db.execute.side_effect = execute_results

        request = MagicMock()
        request.selected_member_ids = [1, 2, 3]
        request.title = "Bulk Offer"
        request.offer_type = "discount"
        request.description = "desc"
        request.benefit = "20%"
        request.valid_until = None
        request.target_type = "highest_risk"

        with patch("app.services.admin.admin_retention_offer.predict_churn_risk", new_callable=AsyncMock) as mock_predict:
            mock_predict.return_value = "High"
            result = await create_and_send_offer_service(mock_db, GYM_ID, request)

        # 1 add for the offer + 3 adds for recipients
        assert mock_db.add.call_count == 4
        assert result["sent_to"] == 3