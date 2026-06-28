# tests/services/client/test_client_profile_service.py
#
# Run with:
#   pytest test/services/client/test_client_profile_service.py -v

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import date
from app.services.client.client_profile import (
    _calculate_age,
    _build_response,
    get_client_profile,
    update_client_profile,
)
from app.models import User, Client
from app.schemas.client.client_profile_schema import ClientProfileUpdate, ClientProfileResponse


# ── Helpers ───────────────────────────────────────────────────────────────────

def _make_user(user_id: int = 1, name: str = "Aisha", email: str = "aisha@titan.com", phone: str = "0501234567") -> MagicMock:
    u = MagicMock(spec=User)
    u.userID = user_id
    u.name = name
    u.email = email
    u.phone = phone
    return u


def _make_client(
    client_id: int = 1,
    user_id: int = 1,
    gender: str = "female",
    fitness_goal: str = "strength",
    dob: date | None = date(1995, 6, 15),
    bio: str = "Fitness enthusiast",
    emergency_contact: str = "0509999999",
) -> MagicMock:
    c = MagicMock(spec=Client)
    c.clientID = client_id
    c.userID = user_id
    c.gender = gender
    c.fitness_goal = fitness_goal
    c.date_of_birth = dob
    c.bio = bio
    c.emergency_contact = emergency_contact
    return c


def _db_returning(*scalars) -> AsyncMock:
    """Returns each scalar in order across multiple execute() calls."""
    mocks = []
    for val in scalars:
        r = MagicMock()
        r.scalar_one_or_none.return_value = val
        mocks.append(r)
    db = AsyncMock()
    db.execute = AsyncMock(side_effect=mocks)
    return db


def _make_payload(**kwargs) -> ClientProfileUpdate:
    defaults = dict(
        name=None,
        phone=None,
        gender=None,
        fitness_goal=None,
        date_of_birth=None,
        bio=None,
        emergency_contact=None,
    )
    defaults.update(kwargs)
    return ClientProfileUpdate(**defaults)


# ════════════════════════════════════════════════════════════════════════════
# _calculate_age  (pure function — no DB)
# ════════════════════════════════════════════════════════════════════════════

class TestCalculateAge:

    def test_age_when_birthday_already_passed_this_year(self):
        today = date.today()
        dob = date(today.year - 25, today.month - 1 if today.month > 1 else 1, 1)
        assert _calculate_age(dob) == 25

    def test_age_when_birthday_not_yet_this_year(self):
        today = date.today()
        # Birthday is next month — hasn't happened yet
        month = today.month + 1 if today.month < 12 else 12
        dob = date(today.year - 25, month, 1)
        age = _calculate_age(dob)
        assert age in (24, 25)  # depends on exact month

    def test_age_on_exact_birthday(self):
        today = date.today()
        dob = date(today.year - 30, today.month, today.day)
        assert _calculate_age(dob) == 30

    def test_age_one_day_before_birthday(self):
        today = date.today()
        tomorrow = date(today.year, today.month, today.day)
        # dob is tomorrow's date but 20 years ago — birthday hasn't come yet
        if today.month == 12 and today.day == 31:
            pytest.skip("Edge case: Dec 31")
        dob = date(today.year - 20, today.month, today.day + 1) if today.day < 28 else date(today.year - 20, today.month, today.day)
        age = _calculate_age(dob)
        assert age in (19, 20)

    def test_age_is_zero_for_newborn(self):
        today = date.today()
        assert _calculate_age(today) == 0

    def test_age_for_known_dob(self):
        # Fixed date: born Jan 1 1990, today patched to Jan 1 2025 → age 35
        with patch("app.services.client.client_profile.date") as mock_date:
            mock_date.today.return_value = date(2025, 1, 1)
            mock_date.side_effect = lambda *a, **kw: date(*a, **kw)
            age = _calculate_age(date(1990, 1, 1))
        assert age == 35

    def test_birthday_not_yet_in_known_year(self):
        # Born Dec 31 1990, today is Jan 1 2025 → age is 34, not 35
        with patch("app.services.client.client_profile.date") as mock_date:
            mock_date.today.return_value = date(2025, 1, 1)
            mock_date.side_effect = lambda *a, **kw: date(*a, **kw)
            age = _calculate_age(date(1990, 12, 31))
        assert age == 34


# ════════════════════════════════════════════════════════════════════════════
# _build_response  (pure function — no DB)
# ════════════════════════════════════════════════════════════════════════════

class TestBuildResponse:

    def test_returns_client_profile_response(self):
        user = _make_user()
        client = _make_client(dob=date(1995, 1, 1))
        result = _build_response(user, client)
        assert isinstance(result, ClientProfileResponse)

    def test_maps_user_fields_correctly(self):
        user = _make_user(user_id=7, name="Nour", email="nour@titan.com", phone="0501111111")
        client = _make_client()
        result = _build_response(user, client)
        assert result.userID == 7
        assert result.name == "Nour"
        assert result.email == "nour@titan.com"
        assert result.phone == "0501111111"

    def test_maps_client_fields_correctly(self):
        user = _make_user()
        client = _make_client(
            client_id=5,
            gender="male",
            fitness_goal="weight loss",
            dob=date(1990, 3, 20),
            bio="Runner",
            emergency_contact="0508888888",
        )
        result = _build_response(user, client)
        assert result.clientID == 5
        assert result.gender == "male"
        assert result.fitness_goal == "weight loss"
        assert result.date_of_birth == date(1990, 3, 20)
        assert result.bio == "Runner"
        assert result.emergency_contact == "0508888888"

    def test_age_is_calculated_when_dob_provided(self):
        user = _make_user()
        client = _make_client(dob=date(1990, 1, 1))
        result = _build_response(user, client)
        assert result.age is not None
        assert result.age > 0

    def test_age_is_none_when_dob_is_none(self):
        user = _make_user()
        client = _make_client(dob=None)
        result = _build_response(user, client)
        assert result.age is None


# ════════════════════════════════════════════════════════════════════════════
# get_client_profile
# ════════════════════════════════════════════════════════════════════════════

class TestGetClientProfile:

    async def test_returns_profile_when_user_and_client_found(self):
        user = _make_user()
        client = _make_client()
        db = _db_returning(user, client)

        result = await get_client_profile(1, db)

        assert result is not None
        assert isinstance(result, ClientProfileResponse)

    async def test_returns_none_when_user_not_found(self):
        db = _db_returning(None)

        result = await get_client_profile(99, db)

        assert result is None

    async def test_returns_none_when_client_not_found(self):
        user = _make_user()
        db = _db_returning(user, None)

        result = await get_client_profile(1, db)

        assert result is None

    async def test_queries_db_twice_on_success(self):
        user = _make_user()
        client = _make_client()
        db = _db_returning(user, client)

        await get_client_profile(1, db)

        assert db.execute.await_count == 2

    async def test_queries_db_once_when_user_not_found(self):
        db = _db_returning(None)

        await get_client_profile(99, db)

        assert db.execute.await_count == 1

    async def test_correct_name_in_response(self):
        user = _make_user(name="Fatima")
        client = _make_client()
        db = _db_returning(user, client)

        result = await get_client_profile(1, db)

        assert result.name == "Fatima"

    async def test_age_none_when_no_dob(self):
        user = _make_user()
        client = _make_client(dob=None)
        db = _db_returning(user, client)

        result = await get_client_profile(1, db)

        assert result.age is None


# ════════════════════════════════════════════════════════════════════════════
# update_client_profile
# ════════════════════════════════════════════════════════════════════════════

class TestUpdateClientProfile:

    async def _make_update_db(self, user, client) -> AsyncMock:
        db = _db_returning(user, client)
        db.commit = AsyncMock()
        db.refresh = AsyncMock()
        return db

    async def test_returns_none_when_user_not_found(self):
        db = _db_returning(None)
        db.commit = AsyncMock()
        db.refresh = AsyncMock()

        result = await update_client_profile(99, _make_payload(), db)

        assert result is None

    async def test_returns_none_when_client_not_found(self):
        user = _make_user()
        db = _db_returning(user, None)
        db.commit = AsyncMock()
        db.refresh = AsyncMock()

        result = await update_client_profile(1, _make_payload(), db)

        assert result is None

    async def test_returns_response_on_success(self):
        user = _make_user()
        client = _make_client()
        db = await self._make_update_db(user, client)

        result = await update_client_profile(1, _make_payload(), db)

        assert isinstance(result, ClientProfileResponse)

    async def test_updates_user_name(self):
        user = _make_user(name="Old Name")
        client = _make_client()
        db = await self._make_update_db(user, client)

        await update_client_profile(1, _make_payload(name="New Name"), db)

        assert user.name == "New Name"

    async def test_updates_user_phone(self):
        user = _make_user(phone="0500000000")
        client = _make_client()
        db = await self._make_update_db(user, client)

        await update_client_profile(1, _make_payload(phone="01099999999"), db)

        assert user.phone == "01099999999"

    async def test_updates_client_gender(self):
        user = _make_user()
        client = _make_client(gender="female")
        db = await self._make_update_db(user, client)

        await update_client_profile(1, _make_payload(gender="male"), db)

        assert client.gender == "male"

    async def test_updates_client_fitness_goal(self):
        user = _make_user()
        client = _make_client(fitness_goal="strength")
        db = await self._make_update_db(user, client)

        await update_client_profile(1, _make_payload(fitness_goal="endurance"), db)

        assert client.fitness_goal == "endurance"

    async def test_updates_client_dob(self):
        user = _make_user()
        client = _make_client(dob=date(1990, 1, 1))
        db = await self._make_update_db(user, client)

        new_dob = date(1995, 5, 20)
        await update_client_profile(1, _make_payload(date_of_birth=new_dob), db)

        assert client.date_of_birth == new_dob

    async def test_updates_client_bio(self):
        user = _make_user()
        client = _make_client(bio="Old bio")
        db = await self._make_update_db(user, client)

        await update_client_profile(1, _make_payload(bio="New bio"), db)

        assert client.bio == "New bio"

    async def test_updates_emergency_contact(self):
        user = _make_user()
        client = _make_client(emergency_contact="0500000000")
        db = await self._make_update_db(user, client)

        await update_client_profile(1, _make_payload(emergency_contact="0511111111"), db)

        assert client.emergency_contact == "0511111111"

    async def test_none_fields_are_not_updated(self):
        user = _make_user(name="Original")
        client = _make_client(gender="female")
        db = await self._make_update_db(user, client)

        # Only updating phone — name and gender should stay unchanged
        await update_client_profile(1, _make_payload(phone="01099999999"), db)

        assert user.name == "Original"
        assert client.gender == "female"

    async def test_commits_to_db(self):
        user = _make_user()
        client = _make_client()
        db = await self._make_update_db(user, client)

        await update_client_profile(1, _make_payload(name="Test"), db)

        db.commit.assert_awaited_once()

    async def test_refreshes_user_and_client(self):
        user = _make_user()
        client = _make_client()
        db = await self._make_update_db(user, client)

        await update_client_profile(1, _make_payload(), db)

        assert db.refresh.await_count == 2