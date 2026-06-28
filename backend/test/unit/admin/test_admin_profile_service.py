import pytest
from fastapi import HTTPException
from unittest.mock import MagicMock, AsyncMock
from test.helpers import make_user
from app.services.admin.admin_profile_service import get_profile, update_profile


def make_execute_result(scalar_value=None, scalars_first=None):
    """
    Handles:
    - result.scalars().first()  → for Admin lookup
    - result.scalar()           → for gym count
    """
    result = MagicMock()
    result.scalars.return_value.first.return_value = scalars_first
    result.scalar.return_value = scalar_value
    return result


# get_profile

class TestGetProfile:

    async def test_raises_if_not_admin(self, mock_db, admin_user):
        # Admin lookup returns None
        result = make_execute_result(scalars_first=None)
        mock_db.execute.return_value = result

        with pytest.raises(HTTPException) as exc:
            await get_profile(mock_db, admin_user)
        assert exc.value.status_code == 403     #unauthorized

    async def test_returns_profile(self, mock_db, admin_user, mock_admin):
        admin_result = make_execute_result(scalars_first=mock_admin)
        gym_count_result = make_execute_result(scalar_value=3)
        mock_db.execute.side_effect = [admin_result, gym_count_result]

        result = await get_profile(mock_db, admin_user)

        assert result["adminID"] == mock_admin.adminID
        assert result["userID"] == admin_user.userID
        assert result["name"] == admin_user.name
        assert result["email"] == admin_user.email
        assert result["phone"] == admin_user.phone
        assert result["total_gyms"] == 3

    async def test_returns_correct_gym_count(self, mock_db, admin_user, mock_admin):
        admin_result = make_execute_result(scalars_first=mock_admin)
        gym_count_result = make_execute_result(scalar_value=5)
        mock_db.execute.side_effect = [admin_result, gym_count_result]

        result = await get_profile(mock_db, admin_user)

        assert result["total_gyms"] == 5

    async def test_created_at_none_if_missing(self, mock_db, mock_admin):
        # User without created_at attribute
        user = make_user()
        del user.created_at  # remove the attribute entirely

        admin_result = make_execute_result(scalars_first=mock_admin)
        gym_count_result = make_execute_result(scalar_value=0)
        mock_db.execute.side_effect = [admin_result, gym_count_result]

        result = await get_profile(mock_db, user)

        assert result["created_at"] is None



# update_profile

class TestUpdateProfile:

    async def test_raises_if_not_admin(self, mock_db, admin_user, mock_admin_profile_update):
        result = make_execute_result(scalars_first=None)
        mock_db.execute.return_value = result

        with pytest.raises(HTTPException) as exc:
            await update_profile(mock_db, admin_user, mock_admin_profile_update)
        assert exc.value.status_code == 403

    async def test_updates_name(self, mock_db, admin_user, mock_admin, mock_admin_profile_update):
        mock_admin_profile_update.name = "New Name"
        mock_admin_profile_update.phone = None
        result = make_execute_result(scalars_first=mock_admin)
        mock_db.execute.return_value = result

        await update_profile(mock_db, admin_user, mock_admin_profile_update)

        assert admin_user.name == "New Name"

    async def test_updates_phone(self, mock_db, admin_user, mock_admin, mock_admin_profile_update):
        mock_admin_profile_update.name = None
        mock_admin_profile_update.phone = "01111111111"
        result = make_execute_result(scalars_first=mock_admin)
        mock_db.execute.return_value = result

        await update_profile(mock_db, admin_user, mock_admin_profile_update)

        assert admin_user.phone == "01111111111"

    async def test_updates_both_name_and_phone(self, mock_db, admin_user, mock_admin, mock_admin_profile_update):
        result = make_execute_result(scalars_first=mock_admin)
        mock_db.execute.return_value = result

        await update_profile(mock_db, admin_user, mock_admin_profile_update)

        assert admin_user.name == mock_admin_profile_update.name
        assert admin_user.phone == mock_admin_profile_update.phone

    async def test_skips_name_if_none(self, mock_db, admin_user, mock_admin, mock_admin_profile_update):
        mock_admin_profile_update.name = None
        original_name = admin_user.name
        result = make_execute_result(scalars_first=mock_admin)
        mock_db.execute.return_value = result

        await update_profile(mock_db, admin_user, mock_admin_profile_update)

        assert admin_user.name == original_name  # unchanged

    async def test_commits_on_success(self, mock_db, admin_user, mock_admin, mock_admin_profile_update):
        result = make_execute_result(scalars_first=mock_admin)
        mock_db.execute.return_value = result

        await update_profile(mock_db, admin_user, mock_admin_profile_update)

        mock_db.commit.assert_called_once()

    async def test_returns_success_message(self, mock_db, admin_user, mock_admin, mock_admin_profile_update):
        result = make_execute_result(scalars_first=mock_admin)
        mock_db.execute.return_value = result

        response = await update_profile(mock_db, admin_user, mock_admin_profile_update)

        assert response["message"] == "Profile updated successfully"