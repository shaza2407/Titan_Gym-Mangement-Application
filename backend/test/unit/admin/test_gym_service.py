# test/unit/admin/test_gym_service.py
import pytest
from fastapi import HTTPException
from unittest.mock import MagicMock, AsyncMock, patch, call
from app.services.admin.gym_service import (
    get_gym_by_admin,
    get_all_gyms_by_admin,
    create_gym,
    update_gym,
    delete_gym,
    get_dashboard_stats,
    get_total_members,
    get_member_count,
    get_coach_count,
    generate_qr_code,
)

ADMIN_ID = 10
GYM_ID = 5


def scalar_result(value):
    """For scalar() calls - count queries."""
    r = MagicMock()
    r.scalar.return_value = value
    return r


def scalars_first_result(value):
    """For scalars().first() calls - single object queries."""
    r = MagicMock()
    r.scalars.return_value.first.return_value = value
    return r


def scalars_all_result(values):
    """For scalars().all() calls - list queries."""
    r = MagicMock()
    r.scalars.return_value.all.return_value = values
    return r



# generate_qr_code  (pure function, no DB)

class TestGenerateQrCode:

    def test_returns_base64_string(self):
        result = generate_qr_code(1, "Titan Gym")
        assert isinstance(result, str)
        assert len(result) > 0

    def test_different_gyms_produce_different_codes(self):
        code1 = generate_qr_code(1, "Gym A")
        code2 = generate_qr_code(2, "Gym B")
        assert code1 != code2




# get_gym_by_admin

class TestGetGymByAdmin:

    async def test_returns_gym(self, mock_db, mock_gym):
        mock_db.execute.return_value = scalars_first_result(mock_gym)

        result = await get_gym_by_admin(mock_db, GYM_ID, ADMIN_ID)

        assert result == mock_gym

    async def test_raises_404_if_not_found(self, mock_db):
        mock_db.execute.return_value = scalars_first_result(None)

        with pytest.raises(HTTPException) as exc:
            await get_gym_by_admin(mock_db, GYM_ID, ADMIN_ID)
        assert exc.value.status_code == 404



# get_all_gyms_by_admin

class TestGetAllGymsByAdmin:

    async def test_returns_list_of_gyms(self, mock_db, mock_gym):
        mock_db.execute.return_value = scalars_all_result([mock_gym])

        result = await get_all_gyms_by_admin(mock_db, ADMIN_ID)

        assert len(result) == 1
        assert result[0] == mock_gym

    async def test_returns_empty_list(self, mock_db):
        mock_db.execute.return_value = scalars_all_result([])

        result = await get_all_gyms_by_admin(mock_db, ADMIN_ID)

        assert result == []



# create_gym

class TestCreateGym:

    async def test_creates_gym_successfully(self, mock_db, mock_gym_create, mock_gym):
        # flush gives gym an ID, final select returns the full gym
        mock_db.flush = AsyncMock()
        mock_db.execute.return_value = scalars_first_result(mock_gym)

        with patch("app.services.admin.gym_service.generate_qr_code", return_value="qr_base64"):
            result = await create_gym(mock_db, mock_gym_create, ADMIN_ID)

        mock_db.add.assert_called()
        mock_db.commit.assert_called_once()
        assert result == mock_gym

    async def test_adds_machines_to_inventory(self, mock_db, mock_gym_create, mock_gym):
        mock_db.flush = AsyncMock()
        mock_db.execute.return_value = scalars_first_result(mock_gym)

        with patch("app.services.admin.gym_service.generate_qr_code", return_value="qr"):
            await create_gym(mock_db, mock_gym_create, ADMIN_ID)

        # add called at least twice: once for Gym, once per machine
        assert mock_db.add.call_count >= 2

    async def test_rollback_on_integrity_error(self, mock_db, mock_gym_create):
        from sqlalchemy.exc import IntegrityError
        mock_db.flush = AsyncMock()
        mock_db.commit.side_effect = IntegrityError("", {}, Exception())

        with patch("app.services.admin.gym_service.generate_qr_code", return_value="qr"):
            with pytest.raises(HTTPException) as exc:
                await create_gym(mock_db, mock_gym_create, ADMIN_ID)

        assert exc.value.status_code == 400
        mock_db.rollback.assert_called_once()


    async def test_sets_admin_id(self, mock_db, mock_gym_create, mock_gym):
        mock_db.flush = AsyncMock()
        mock_db.execute.return_value = scalars_first_result(mock_gym)

        with patch("app.services.admin.gym_service.generate_qr_code", return_value="qr"):
            await create_gym(mock_db, mock_gym_create, ADMIN_ID)

        # Check that the object passed to db.add() has adminID set
        added_object = mock_db.add.call_args_list[0][0][0]
        assert added_object.adminID == ADMIN_ID



# update_gym

class TestUpdateGym:

    async def test_updates_fields(self, mock_db, mock_gym, mock_gym_update):
        mock_gym_update.model_dump.return_value = {"gymName": "New Name"}
        # First call: get_gym_by_admin, second call: re-fetch after commit
        mock_db.execute.side_effect = [
            scalars_first_result(mock_gym),
            scalars_first_result(mock_gym),
        ]

        await update_gym(mock_db, GYM_ID, mock_gym_update, ADMIN_ID)

        assert mock_gym.gymName == "New Name"
        mock_db.commit.assert_called_once()

    async def test_replaces_machines_if_provided(self, mock_db, mock_gym, mock_gym_update):
        mock_gym_update.model_dump.return_value = {
            "machines": [{"machineName": "Bike", "machineType": "Cardio", "quantity": 2}]
        }
        mock_db.execute.side_effect = [
            scalars_first_result(mock_gym),
            MagicMock(),               # delete execute
            scalars_first_result(mock_gym),
        ]

        await update_gym(mock_db, GYM_ID, mock_gym_update, ADMIN_ID)

        mock_db.add.assert_called()

    async def test_rollback_on_integrity_error(self, mock_db, mock_gym, mock_gym_update):
        from sqlalchemy.exc import IntegrityError
        mock_gym_update.model_dump.return_value = {"gymName": "Bad"}
        mock_db.execute.return_value = scalars_first_result(mock_gym)
        mock_db.commit.side_effect = IntegrityError("", {}, Exception())

        with pytest.raises(HTTPException) as exc:
            await update_gym(mock_db, GYM_ID, mock_gym_update, ADMIN_ID)

        assert exc.value.status_code == 400
        mock_db.rollback.assert_called_once()

    async def test_raises_404_if_gym_not_found(self, mock_db, mock_gym_update):
        mock_db.execute.return_value = scalars_first_result(None)

        with pytest.raises(HTTPException) as exc:
            await update_gym(mock_db, GYM_ID, mock_gym_update, ADMIN_ID)
        assert exc.value.status_code == 404



# delete_gym

class TestDeleteGym:

    async def test_deletes_gym(self, mock_db, mock_gym):
        mock_db.execute.return_value = scalars_first_result(mock_gym)
        mock_db.delete = AsyncMock()

        result = await delete_gym(mock_db, GYM_ID, ADMIN_ID)

        mock_db.delete.assert_called_once_with(mock_gym)
        mock_db.commit.assert_called_once()
        assert str(GYM_ID) in result["detail"]

    async def test_raises_404_if_gym_not_found(self, mock_db):
        mock_db.execute.return_value = scalars_first_result(None)

        with pytest.raises(HTTPException) as exc:
            await delete_gym(mock_db, GYM_ID, ADMIN_ID)
        assert exc.value.status_code == 404



# get_dashboard_stats

class TestGetDashboardStats:

    async def test_returns_stats(self, mock_db, mock_gym):
        mock_db.execute.side_effect = [
            scalars_first_result(mock_gym),  # get_gym_by_admin
            scalar_result(50),               # total members
            scalar_result(30),               # active subscriptions
            scalar_result(10),               # today attendance
            scalar_result(5),                # total classes
        ]

        result = await get_dashboard_stats(mock_db, GYM_ID, ADMIN_ID)

        assert result["gymID"] == mock_gym.gymID
        assert result["gymName"] == mock_gym.gymName
        assert result["totalMembers"] == 50
        assert result["activeSubscriptions"] == 30
        assert result["todayAttendance"] == 10
        assert result["totalClasses"] == 5

    async def test_defaults_to_zero_when_no_data(self, mock_db, mock_gym):
        mock_db.execute.side_effect = [
            scalars_first_result(mock_gym),
            scalar_result(None),  # total members → should default to 0
            scalar_result(None),
            scalar_result(None),
            scalar_result(None),
        ]

        result = await get_dashboard_stats(mock_db, GYM_ID, ADMIN_ID)

        assert result["totalMembers"] == 0
        assert result["activeSubscriptions"] == 0
        assert result["todayAttendance"] == 0
        assert result["totalClasses"] == 0

    async def test_raises_404_if_gym_not_found(self, mock_db):
        mock_db.execute.return_value = scalars_first_result(None)

        with pytest.raises(HTTPException) as exc:
            await get_dashboard_stats(mock_db, GYM_ID, ADMIN_ID)
        assert exc.value.status_code == 404



# get_total_members

class TestGetTotalMembers:

    async def test_returns_total(self, mock_db, mock_admin):
        mock_db.execute.side_effect = [
            scalars_first_result(mock_admin),  # admin lookup
            scalar_result(100),                # count
        ]

        result = await get_total_members(mock_db, user_id=1)

        assert result == 100

    async def test_raises_403_if_not_admin(self, mock_db):
        mock_db.execute.return_value = scalars_first_result(None)

        with pytest.raises(HTTPException) as exc:
            await get_total_members(mock_db, user_id=99)
        assert exc.value.status_code == 403

    async def test_returns_zero_if_no_members(self, mock_db, mock_admin):
        mock_db.execute.side_effect = [
            scalars_first_result(mock_admin),
            scalar_result(None),
        ]

        result = await get_total_members(mock_db, user_id=1)

        assert result == 0



# get_member_count

class TestGetMemberCount:

    async def test_returns_active_member_count(self, mock_db):
        mock_db.execute.return_value = scalar_result(25)

        result = await get_member_count(mock_db, GYM_ID)

        assert result == 25

    async def test_returns_zero_if_none(self, mock_db):
        mock_db.execute.return_value = scalar_result(None)

        result = await get_member_count(mock_db, GYM_ID)

        assert result == 0



# get_coach_count

class TestGetCoachCount:

    async def test_returns_coach_count(self, mock_db):
        mock_db.execute.return_value = scalar_result(8)

        result = await get_coach_count(mock_db, GYM_ID)

        assert result == 8

    async def test_returns_zero_if_none(self, mock_db):
        mock_db.execute.return_value = scalar_result(None)

        result = await get_coach_count(mock_db, GYM_ID)

        assert result == 0