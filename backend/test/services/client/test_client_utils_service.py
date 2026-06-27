# tests/services/client/test_client_utils.py
#
# Run with:
#   pytest test/services/client/test_client_utils_service.py -v

import pytest
from unittest.mock import AsyncMock, MagicMock
from fastapi import HTTPException

from app.services.client.client_utils import (
    get_client_by_user_id,
    get_client_or_404,
    get_membership,
    get_client_gymID,
    get_client_gym_or_404,
)
from app.models.client import Client
from app.models.Gym import Gym
from app.models.gym_clients_membership import GymClientMembership


# ── Helpers ───────────────────────────────────────────────────────────────────

def _make_client(user_id: int = 1, client_id: int = 1) -> MagicMock:
    c = MagicMock(spec=Client)
    c.userID = user_id
    c.clientID = client_id
    return c


def _make_gym(gym_id: int = 1, name: str = "Titan Gym") -> MagicMock:
    g = MagicMock(spec=Gym)
    g.gymID = gym_id
    g.gymName = name
    return g


def _make_membership(client_id: int = 1, gym_id: int = 1) -> MagicMock:
    m = MagicMock(spec=GymClientMembership)
    m.clientID = client_id
    m.gymID = gym_id
    return m


def _db_returning(*scalars) -> AsyncMock:
    """
    Build a mock DB that returns each scalar value in order across
    multiple execute() calls.
    """
    mocks = []
    for val in scalars:
        r = MagicMock()
        r.scalar_one_or_none.return_value = val
        mocks.append(r)
    db = AsyncMock()
    db.execute = AsyncMock(side_effect=mocks)
    return db


# ════════════════════════════════════════════════════════════════════════════
# get_client_by_user_id
# ════════════════════════════════════════════════════════════════════════════

class TestGetClientByUserId:

    async def test_returns_client_when_found(self):
        client = _make_client(user_id=1)
        db = _db_returning(client)

        result = await get_client_by_user_id(1, db)

        assert result is client

    async def test_raises_403_when_client_not_found(self):
        db = _db_returning(None)

        with pytest.raises(HTTPException) as exc:
            await get_client_by_user_id(1, db)

        assert exc.value.status_code == 403

    async def test_default_error_detail_message(self):
        db = _db_returning(None)

        with pytest.raises(HTTPException) as exc:
            await get_client_by_user_id(1, db)

        assert exc.value.detail == "Only clients can perform this action."

    async def test_custom_detail_message(self):
        db = _db_returning(None)

        with pytest.raises(HTTPException) as exc:
            await get_client_by_user_id(1, db, detail="Custom error")

        assert exc.value.detail == "Custom error"

    async def test_queries_db_once(self):
        client = _make_client()
        db = _db_returning(client)

        await get_client_by_user_id(1, db)

        db.execute.assert_awaited_once()


# ════════════════════════════════════════════════════════════════════════════
# get_client_or_404
# ════════════════════════════════════════════════════════════════════════════

class TestGetClientOr404:

    async def test_returns_client_when_found(self):
        client = _make_client(user_id=5)
        db = _db_returning(client)

        result = await get_client_or_404(5, db)

        assert result is client

    async def test_raises_404_when_not_found(self):
        db = _db_returning(None)

        with pytest.raises(HTTPException) as exc:
            await get_client_or_404(99, db)

        assert exc.value.status_code == 404

    async def test_404_detail_message(self):
        db = _db_returning(None)

        with pytest.raises(HTTPException) as exc:
            await get_client_or_404(99, db)

        assert exc.value.detail == "Client not found"

    async def test_queries_db_once(self):
        client = _make_client()
        db = _db_returning(client)

        await get_client_or_404(1, db)

        db.execute.assert_awaited_once()


# ════════════════════════════════════════════════════════════════════════════
# get_membership
# ════════════════════════════════════════════════════════════════════════════

class TestGetMembership:

    async def test_returns_membership_when_found(self):
        membership = _make_membership(client_id=1, gym_id=2)
        db = _db_returning(membership)

        result = await get_membership(1, db)

        assert result is membership

    async def test_returns_none_when_not_found(self):
        db = _db_returning(None)

        result = await get_membership(99, db)

        assert result is None

    async def test_does_not_raise_when_not_found(self):
        db = _db_returning(None)

        # Should return None, not raise
        result = await get_membership(99, db)
        assert result is None

    async def test_queries_db_once(self):
        db = _db_returning(None)

        await get_membership(1, db)

        db.execute.assert_awaited_once()


# ════════════════════════════════════════════════════════════════════════════
# get_client_gymID
# ════════════════════════════════════════════════════════════════════════════

class TestGetClientGymID:

    async def test_returns_gym_id_when_membership_exists(self):
        result_mock = MagicMock()
        result_mock.scalar_one_or_none.return_value = 7
        db = AsyncMock()
        db.execute = AsyncMock(return_value=result_mock)

        result = await get_client_gymID(1, db)

        assert result == 7

    async def test_returns_none_when_no_membership(self):
        result_mock = MagicMock()
        result_mock.scalar_one_or_none.return_value = None
        db = AsyncMock()
        db.execute = AsyncMock(return_value=result_mock)

        result = await get_client_gymID(99, db)

        assert result is None

    async def test_does_not_raise_when_no_membership(self):
        result_mock = MagicMock()
        result_mock.scalar_one_or_none.return_value = None
        db = AsyncMock()
        db.execute = AsyncMock(return_value=result_mock)

        result = await get_client_gymID(99, db)
        assert result is None

    async def test_queries_db_once(self):
        result_mock = MagicMock()
        result_mock.scalar_one_or_none.return_value = None
        db = AsyncMock()
        db.execute = AsyncMock(return_value=result_mock)

        await get_client_gymID(1, db)

        db.execute.assert_awaited_once()


# ════════════════════════════════════════════════════════════════════════════
# get_client_gym_or_404
# ════════════════════════════════════════════════════════════════════════════

class TestGetClientGymOr404:

    async def test_returns_gym_when_membership_and_gym_exist(self):
        membership = _make_membership(client_id=1, gym_id=3)
        gym = _make_gym(gym_id=3)
        db = _db_returning(membership, gym)

        result = await get_client_gym_or_404(1, db)

        assert result is gym

    async def test_raises_404_when_no_membership(self):
        db = _db_returning(None)

        with pytest.raises(HTTPException) as exc:
            await get_client_gym_or_404(1, db)

        assert exc.value.status_code == 404
        assert exc.value.detail == "No gym membership found for this client."

    async def test_raises_404_when_membership_exists_but_gym_not_found(self):
        membership = _make_membership(client_id=1, gym_id=99)
        db = _db_returning(membership, None)  # gym query returns None

        with pytest.raises(HTTPException) as exc:
            await get_client_gym_or_404(1, db)

        assert exc.value.status_code == 404
        assert exc.value.detail == "Gym not found."

    async def test_queries_db_twice_on_success(self):
        membership = _make_membership()
        gym = _make_gym()
        db = _db_returning(membership, gym)

        await get_client_gym_or_404(1, db)

        assert db.execute.await_count == 2

    async def test_queries_db_once_when_no_membership(self):
        # Stops after first query if no membership found
        db = _db_returning(None)

        with pytest.raises(HTTPException):
            await get_client_gym_or_404(1, db)

        assert db.execute.await_count == 1

    async def test_returns_correct_gym_id(self):
        membership = _make_membership(gym_id=42)
        gym = _make_gym(gym_id=42)
        db = _db_returning(membership, gym)

        result = await get_client_gym_or_404(1, db)

        assert result.gymID == 42