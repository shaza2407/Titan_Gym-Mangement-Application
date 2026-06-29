import pytest
from fastapi import HTTPException
from unittest.mock import MagicMock, AsyncMock, patch
from app.services.admin.admin_coach_management_service import (
    get_coaches_list,
    invite_coach,
    suspend_a_coach,
    unsuspend_a_coach,
    accept_coach_invitation_service,
    decline_coach_invitation_service,
)
from app.models.gym_coachs_membership import CoachMembershipStatus
from test.helpers import (
    make_user, scalar_one_or_none_result,
    scalars_all_result, make_membership_row,
    make_invitation
)


GYM_ID = 5


# get_coaches_list
class TestGetCoachesList:
    async def test_returns_active_coaches(self, mock_db, mock_gym):
        row = make_membership_row(status="active")
        mock_db.execute.side_effect = [
            MagicMock(all=MagicMock(return_value=[row])),
            scalars_all_result([]),
        ]

        result = await get_coaches_list(mock_db, mock_gym)

        assert result.total == 1
        assert result.active == 1

    async def test_returns_pending_invitations(self, mock_db, mock_gym):
        inv = make_invitation()
        mock_db.execute.side_effect = [
            MagicMock(all=MagicMock(return_value=[])),
            scalars_all_result([inv]),
        ]

        result = await get_coaches_list(mock_db, mock_gym)

        assert result.pending == 1
        assert result.coaches[0].status == "pending"

    async def test_search_filters_by_name(self, mock_db, mock_gym):
        row = make_membership_row(status="active")
        row[2].name = "John Doe"
        row[2].email = "john@example.com"
        mock_db.execute.side_effect = [
            MagicMock(all=MagicMock(return_value=[row])),
            scalars_all_result([]),
        ]

        result = await get_coaches_list(mock_db, mock_gym, search="Mo")

        assert result.total == 0

    async def test_search_excludes_non_matching(self, mock_db, mock_gym):
        row = make_membership_row(status="active")
        row[2].name = "John Doe"
        row[2].email = "john@example.com"
        mock_db.execute.side_effect = [
            MagicMock(all=MagicMock(return_value=[row])),
            scalars_all_result([]),
        ]

        result = await get_coaches_list(mock_db, mock_gym, search="xyz")
        assert result.total == 0

    async def test_returns_empty_when_no_coaches(self, mock_db, mock_gym):
        mock_db.execute.side_effect = [
            MagicMock(all=MagicMock(return_value=[])),
            scalars_all_result([]),
        ]

        result = await get_coaches_list(mock_db, mock_gym)
        assert result.total == 0
        assert result.coaches == []


# invite_coach
class TestInviteCoach:
    async def test_raises_404_if_user_not_found(self, mock_db, mock_gym):
        body = MagicMock()
        body.email = "notfound@example.com"
        mock_db.execute.return_value = scalar_one_or_none_result(None)

        with pytest.raises(HTTPException) as exc:
            await invite_coach(mock_db, mock_gym, body)
        assert exc.value.status_code == 404

    async def test_raises_400_if_user_not_a_coach(self, mock_db, mock_gym):
        body = MagicMock()
        body.email = "client@example.com"
        user = make_user(role="client")
        mock_db.execute.return_value = scalar_one_or_none_result(user)

        with pytest.raises(HTTPException) as exc:
            await invite_coach(mock_db, mock_gym, body)
        assert exc.value.status_code == 400

    async def test_raises_400_if_already_member(self, mock_db, mock_gym):
        body = MagicMock()
        body.email = "coach@example.com"
        user = make_user(role="coach")
        existing_membership = MagicMock()
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(user),
            scalar_one_or_none_result(existing_membership),
        ]

        with pytest.raises(HTTPException) as exc:
            await invite_coach(mock_db, mock_gym, body)
        assert exc.value.status_code == 400

    async def test_creates_new_invitation(self, mock_db, mock_gym):
        body = MagicMock()
        body.email = "coach@example.com"
        user = make_user(role="coach")
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(user),   # user found
            scalar_one_or_none_result(None),   # not a member
            scalar_one_or_none_result(None),   # no pending invite
        ]

        with patch("app.services.admin.admin_coach_management_service.notify_invite", new_callable=AsyncMock):
            result = await invite_coach(mock_db, mock_gym, body)

        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
        assert result.email == body.email

    async def test_refreshes_existing_invitation(self, mock_db, mock_gym):
        body = MagicMock()
        body.email = "coach@example.com"
        user = make_user(role="coach")
        existing_inv = MagicMock()
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(user),
            scalar_one_or_none_result(None),
            scalar_one_or_none_result(existing_inv),
        ]

        with patch("app.services.admin.admin_coach_management_service.notify_invite", new_callable=AsyncMock):
            result = await invite_coach(mock_db, mock_gym, body)

        mock_db.add.assert_not_called()
        assert result.message == "Invitation sent successfully."


# suspend_a_coach
class TestSuspendACoach:
    async def test_suspends_coach(self, mock_db, mock_gym):
        membership = MagicMock()
        mock_db.execute.return_value = scalar_one_or_none_result(membership)
        result = await suspend_a_coach(mock_db, mock_gym, coach_id=10)

        assert membership.status == CoachMembershipStatus.suspended
        mock_db.commit.assert_called_once()
        assert result["message"] == "Coach suspended successfully."

    async def test_raises_404_if_coach_not_found(self, mock_db, mock_gym):
        mock_db.execute.return_value = scalar_one_or_none_result(None)

        with pytest.raises(HTTPException) as exc:
            await suspend_a_coach(mock_db, mock_gym, coach_id=99)
        assert exc.value.status_code == 404


# unsuspend_a_coach
class TestUnsuspendACoach:
    async def test_unsuspends_coach(self, mock_db, mock_gym):
        membership = MagicMock()
        mock_db.execute.return_value = scalar_one_or_none_result(membership)

        result = await unsuspend_a_coach(mock_db, mock_gym, user_id=10)

        assert membership.status == CoachMembershipStatus.active
        mock_db.commit.assert_called_once()

    async def test_raises_404_if_coach_not_found(self, mock_db, mock_gym):
        mock_db.execute.return_value = scalar_one_or_none_result(None)

        with pytest.raises(HTTPException) as exc:
            await unsuspend_a_coach(mock_db, mock_gym, user_id=99)
        assert exc.value.status_code == 404


# accept_coach_invitation_service
class TestAcceptCoachInvitation:
    async def test_raises_404_if_invitation_not_found(self, mock_db):
        user = make_user(role="coach")
        mock_db.execute.return_value = scalar_one_or_none_result(None)

        with pytest.raises(HTTPException) as exc:
            await accept_coach_invitation_service(mock_db, "bad_token", user)
        assert exc.value.status_code == 404

    async def test_raises_400_if_invitation_expired(self, mock_db):
        from datetime import datetime, timezone, timedelta
        user = make_user(role="coach", email="coach@example.com")
        inv = MagicMock()
        inv.expires_at = datetime.now(timezone.utc) - timedelta(days=1)
        mock_db.execute.return_value = scalar_one_or_none_result(inv)

        with pytest.raises(HTTPException) as exc:
            await accept_coach_invitation_service(mock_db, "token", user)
        assert exc.value.status_code == 400


    async def test_raises_400_if_already_coach_in_gym(self, mock_db):
        from datetime import datetime, timezone, timedelta
        user = make_user(role="coach", email="coach@example.com")
        inv = MagicMock()
        inv.expires_at = datetime.now(timezone.utc) + timedelta(days=1)
        inv.email = "coach@example.com"
        coach = MagicMock()
        already = MagicMock()

        mock_db.execute.side_effect = [
            scalar_one_or_none_result(inv),
            scalar_one_or_none_result(coach),
            scalar_one_or_none_result(already),
        ]

        with pytest.raises(HTTPException) as exc:
            await accept_coach_invitation_service(mock_db, "token", user)
        assert exc.value.status_code == 400

    async def test_creates_membership_on_success(self, mock_db):
        from datetime import datetime, timezone, timedelta
        user = make_user(role="coach", email="coach@example.com")
        inv = MagicMock()
        inv.expires_at = datetime.now(timezone.utc) + timedelta(days=1)
        inv.email = "coach@example.com"
        inv.gymID = GYM_ID
        coach = MagicMock()
        coach.coachID = 1

        mock_db.execute.side_effect = [
            scalar_one_or_none_result(inv),
            scalar_one_or_none_result(coach),
            scalar_one_or_none_result(None),  # not already a coach
        ]
        mock_db.delete = AsyncMock()

        result = await accept_coach_invitation_service(mock_db, "token", user)

        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
        assert "accepted" in result["message"]


# decline_coach_invitation_service
class TestDeclineCoachInvitation:
    async def test_raises_404_if_not_found(self, mock_db):
        user = make_user(role="coach")
        mock_db.execute.return_value = scalar_one_or_none_result(None)

        with pytest.raises(HTTPException) as exc:
            await decline_coach_invitation_service(mock_db, user, "bad_token")
        assert exc.value.status_code == 404


    async def test_deletes_invitation_on_decline(self, mock_db):
        user = make_user(role="coach", email="coach@example.com")
        inv = MagicMock()
        inv.email = "coach@example.com"
        mock_db.execute.return_value = scalar_one_or_none_result(inv)
        mock_db.delete = MagicMock()

        result = await decline_coach_invitation_service(mock_db, user, "token")

        mock_db.delete.assert_called_once_with(inv)
        mock_db.commit.assert_called_once()
        assert result["message"] == "Invitation declined."