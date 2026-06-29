import pytest
from fastapi import HTTPException
from unittest.mock import MagicMock, AsyncMock, patch
from datetime import date, timedelta, timezone, datetime
from app.services.admin.admin_client_management_service import (
    invite_client,
    suspend_a_client,
    unsuspend_a_client,
    cancel_client_invitation,
    accept_client_invitation,
    decline_client_invitation,
    renew_client_membership,
    preview_invitation_service,
)
from app.models.gym_clients_membership import ClientMembershipStatus
from test.helpers import (
    make_user, scalar_one_or_none_result,
    scalars_all_result, make_invite_body,
    make_client_membership
)


GYM_ID = 5


# invite_client
class TestInviteClient:

    async def test_raises_422_if_user_not_found(self, mock_db, mock_gym):
        mock_db.execute.return_value = scalar_one_or_none_result(None)
        with pytest.raises(HTTPException) as exc:
            await invite_client(mock_db, mock_gym, make_invite_body())
        assert exc.value.status_code == 422

    async def test_raises_400_if_already_active_member(self, mock_db, mock_gym):
        user = make_user(role="client")
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(user),
            scalar_one_or_none_result(make_client_membership()),
        ]
        with pytest.raises(HTTPException) as exc:
            await invite_client(mock_db, mock_gym, make_invite_body())
        assert exc.value.status_code == 400


    async def test_creates_new_invitation(self, mock_db, mock_gym):
        body = make_invite_body()
        user = make_user(role="client")
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(user),
            scalar_one_or_none_result(None),
            scalar_one_or_none_result(None),
            scalar_one_or_none_result(None),
            scalar_one_or_none_result(None),
        ]
        with patch("app.services.admin.admin_client_management_service.notify_invite", new_callable=AsyncMock):
            result = await invite_client(mock_db, mock_gym, body)
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
        assert result.email == body.email

    async def test_refreshes_existing_invitation(self, mock_db, mock_gym):
        body = make_invite_body()
        existing_inv = MagicMock()
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(make_user(role="client")),
            scalar_one_or_none_result(None),  # active
            scalar_one_or_none_result(None),  # suspended
            scalar_one_or_none_result(existing_inv),  # existing invitation
            scalar_one_or_none_result(None),  # existing notification
        ]
        with patch("app.services.admin.admin_client_management_service.notify_invite", new_callable=AsyncMock):
            await invite_client(mock_db, mock_gym, body)
        mock_db.add.assert_not_called()
        assert existing_inv.subscription_price == body.subscription_price


# suspend_a_client
class TestSuspendAClient:

    async def test_suspends_active_client(self, mock_db, mock_gym):
        membership = make_client_membership()
        mock_db.execute.return_value = scalar_one_or_none_result(membership)
        result = await suspend_a_client(mock_db, mock_gym, client_id=10)
        assert membership.status == ClientMembershipStatus.suspended
        mock_db.commit.assert_called_once()
        assert result["message"] == "Client suspended successfully."

    async def test_raises_404_if_client_not_found(self, mock_db, mock_gym):
        mock_db.execute.return_value = scalar_one_or_none_result(None)
        with pytest.raises(HTTPException) as exc:
            await suspend_a_client(mock_db, mock_gym, client_id=99)
        assert exc.value.status_code == 404

    async def test_raises_400_if_not_active(self, mock_db, mock_gym):
        membership = MagicMock()
        membership.status = ClientMembershipStatus.suspended
        mock_db.execute.return_value = scalar_one_or_none_result(membership)
        with pytest.raises(HTTPException) as exc:
            await suspend_a_client(mock_db, mock_gym, client_id=10)
        assert exc.value.status_code == 400


# unsuspend_a_client
class TestUnsuspendAClient:

    async def test_unsuspends_client(self, mock_db, mock_gym):
        membership = MagicMock()
        membership.subscription_end = date.today() + timedelta(days=30)
        membership.clientID = 1
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(membership),
            scalar_one_or_none_result(None),
        ]
        result = await unsuspend_a_client(mock_db, mock_gym, client_id=10)
        assert membership.status == ClientMembershipStatus.active
        assert result["message"] == "Client unsuspended successfully."

    async def test_raises_400_if_subscription_expired(self, mock_db, mock_gym):
        membership = MagicMock()
        membership.subscription_end = date.today() - timedelta(days=1)
        mock_db.execute.return_value = scalar_one_or_none_result(membership)
        with pytest.raises(HTTPException) as exc:
            await unsuspend_a_client(mock_db, mock_gym, client_id=10)
        assert exc.value.status_code == 400

    async def test_raises_400_if_active_at_another_gym(self, mock_db, mock_gym):
        membership = MagicMock()
        membership.subscription_end = date.today() + timedelta(days=30)
        membership.clientID = 1
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(membership),
            scalar_one_or_none_result(MagicMock()),
        ]
        with pytest.raises(HTTPException) as exc:
            await unsuspend_a_client(mock_db, mock_gym, client_id=10)
        assert exc.value.status_code == 400


# cancel_client_invitation
class TestCancelClientInvitation:

    async def test_raises_404_if_invitation_not_found(self, mock_db):
        mock_db.execute.return_value = scalar_one_or_none_result(None)
        with pytest.raises(HTTPException) as exc:
            await cancel_client_invitation(mock_db, GYM_ID, "notfound@example.com")
        assert exc.value.status_code == 404

    async def test_deletes_invitation_and_notification(self, mock_db):
        user = make_user()
        notification = MagicMock()
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(MagicMock()),
            scalar_one_or_none_result(user),
            scalars_all_result([notification]),
        ]
        mock_db.delete = AsyncMock()
        result = await cancel_client_invitation(mock_db, GYM_ID, user.email)
        assert mock_db.delete.call_count >= 2
        mock_db.commit.assert_called_once()
        assert result["detail"] == "Invitation cancelled"


# accept_client_invitation
class TestAcceptClientInvitation:
    async def test_raises_404_if_invitation_not_found(self, mock_db):
        mock_db.execute.return_value = scalar_one_or_none_result(None)
        with pytest.raises(HTTPException) as exc:
            await accept_client_invitation(mock_db, GYM_ID, "bad_token", make_user(email="client@example.com"))
        assert exc.value.status_code == 404

    async def test_raises_400_if_expired(self, mock_db):
        inv = MagicMock()
        inv.expires_at = datetime.now(timezone.utc) - timedelta(days=1)
        mock_db.execute.return_value = scalar_one_or_none_result(inv)
        with pytest.raises(HTTPException) as exc:
            await accept_client_invitation(mock_db, GYM_ID, "token", make_user(email="client@example.com"))
        assert exc.value.status_code == 400

    async def test_raises_403_if_email_mismatch(self, mock_db):
        inv = MagicMock()
        inv.expires_at = datetime.now(timezone.utc) + timedelta(days=1)
        inv.email = "client@example.com"
        mock_db.execute.return_value = scalar_one_or_none_result(inv)
        with pytest.raises(HTTPException) as exc:
            await accept_client_invitation(mock_db, GYM_ID, "token", make_user(email="other@example.com"))
        assert exc.value.status_code == 403

    async def test_creates_membership_on_success(self, mock_db):
        user = make_user(email="client@example.com")
        inv = MagicMock()
        inv.expires_at = datetime.now(timezone.utc) + timedelta(days=1)
        inv.email = "client@example.com"
        inv.subscription = "monthly"
        inv.subscription_end = date.today() + timedelta(days=30)
        inv.subscription_price = 100
        inv.duration_count = 1
        client = MagicMock()
        client.clientID = 1
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(inv),
            scalar_one_or_none_result(client),
            scalar_one_or_none_result(None),
            scalar_one_or_none_result(None),
            scalars_all_result([]),
        ]
        mock_db.flush = AsyncMock()
        mock_db.delete = AsyncMock()
        result = await accept_client_invitation(mock_db, GYM_ID, "token", user)
        mock_db.commit.assert_called_once()
        assert "accepted" in result["message"]


# decline_client_invitation
class TestDeclineClientInvitation:
    async def test_raises_403_if_email_mismatch(self, mock_db):
        inv = MagicMock()
        inv.email = "client@example.com"
        mock_db.execute.return_value = scalar_one_or_none_result(inv)
        with pytest.raises(HTTPException) as exc:
            await decline_client_invitation(mock_db, GYM_ID, "token", make_user(email="other@example.com"))
        assert exc.value.status_code == 403

    async def test_deletes_invitation(self, mock_db):
        user = make_user(email="client@example.com")
        inv = MagicMock()
        inv.email = user.email
        mock_db.execute.return_value = scalar_one_or_none_result(inv)
        mock_db.delete = MagicMock()
        result = await decline_client_invitation(mock_db, GYM_ID, "token", user)
        mock_db.delete.assert_called_once_with(inv)
        mock_db.commit.assert_called_once()
        assert result["message"] == "Invitation declined."


# renew_client_membership
class TestRenewClientMembership:
    async def test_raises_404_if_client_not_found(self, mock_db, mock_gym):
        mock_db.execute.return_value = scalar_one_or_none_result(None)
        with pytest.raises(HTTPException) as exc:
            await renew_client_membership(mock_db, mock_gym, client_id=99, body=MagicMock())
        assert exc.value.status_code == 404

    async def test_renews_monthly_membership(self, mock_db, mock_gym):
        membership = make_client_membership(sub_end=date.today() + timedelta(days=5))
        body = MagicMock()
        body.subscription_type = "monthly"
        body.duration_count = 1
        body.price = 100
        mock_db.execute.return_value = scalar_one_or_none_result(membership)
        result = await renew_client_membership(mock_db, mock_gym, client_id=10, body=body)
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
        assert result["subscription"] == "monthly"

    async def test_extends_from_today_if_expired(self, mock_db, mock_gym):
        membership = make_client_membership(sub_end=date.today() - timedelta(days=10))
        body = MagicMock()
        body.subscription_type = "monthly"
        body.duration_count = 1
        body.price = 100
        mock_db.execute.return_value = scalar_one_or_none_result(membership)
        result = await renew_client_membership(mock_db, mock_gym, client_id=10, body=body)
        assert result["message"] == "Membership renewed successfully."


# preview_invitation_service
class TestPreviewInvitationService:
    async def test_raises_404_if_invitation_not_found(self, mock_db):
        mock_db.execute.return_value = scalar_one_or_none_result(None)
        with pytest.raises(HTTPException) as exc:
            await preview_invitation_service(mock_db, make_user(), GYM_ID, "bad_token")
        assert exc.value.status_code == 404

    async def test_returns_no_conflicts_when_no_other_gyms(self, mock_db):
        gym = MagicMock()
        gym.gymName = "Titan Gym"
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(MagicMock()),
            scalar_one_or_none_result(None),
            scalar_one_or_none_result(gym),
        ]
        result = await preview_invitation_service(mock_db, make_user(), GYM_ID, "token")
        assert result["will_suspend_other_memberships"] is False
        assert result["other_active_gyms"] == []

    async def test_returns_conflicts_when_active_at_other_gyms(self, mock_db):
        client = MagicMock()
        client.clientID = 1
        other_gym_row = MagicMock()
        other_gym_row.gymName = "Other Gym"
        gym = MagicMock()
        gym.gymName = "Titan Gym"
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(MagicMock()),
            scalar_one_or_none_result(client),
            MagicMock(all=MagicMock(return_value=[other_gym_row])),
            scalar_one_or_none_result(gym),
        ]
        result = await preview_invitation_service(mock_db, make_user(), GYM_ID, "token")
        assert result["will_suspend_other_memberships"] is True
        assert "Other Gym" in result["other_active_gyms"]