# tests/unit/coach/test_coach_profile.py
import pytest
from datetime import date
from unittest.mock import MagicMock

from test.unit.coach.helpers import (
    make_coach,
)
from app.services.coach.coach_profile import (
    _split_specializations,
    _join_specializations,
    get_coach_profile,
    update_coach_profile,
)


# ── _split_specializations ─────────────────────────────────────────────

class TestSplitSpecializations:

    def test_splits_comma_separated_string(self):
        result = _split_specializations("yoga,pilates,strength")
        assert result == ["yoga", "pilates", "strength"]

    def test_strips_whitespace(self):
        result = _split_specializations("yoga, pilates , strength")
        assert result == ["yoga", "pilates", "strength"]

    def test_returns_none_for_none_input(self):
        assert _split_specializations(None) is None

    def test_returns_none_for_empty_string(self):
        assert _split_specializations("") is None

    def test_single_item_returns_list_with_one_element(self):
        result = _split_specializations("yoga")
        assert result == ["yoga"]

    def test_ignores_empty_segments(self):
        result = _split_specializations("yoga,,pilates")
        assert result == ["yoga", "pilates"]


# ── _join_specializations (pure) ──────────────────────────────────────────────

class TestJoinSpecializations:

    def test_joins_list_with_commas(self):
        result = _join_specializations(["yoga", "pilates", "strength"])
        assert result == "yoga,pilates,strength"

    def test_returns_none_for_none_input(self):
        assert _join_specializations(None) is None

    def test_returns_none_for_empty_list(self):
        assert _join_specializations([]) is None

    def test_single_item_returns_string(self):
        result = _join_specializations(["yoga"])
        assert result == "yoga"

    def test_roundtrip_split_then_join(self):
        original = "yoga,pilates,strength"
        assert _join_specializations(_split_specializations(original)) == original


# ── get_coach_profile ─────────────────────────────────────────────────────────

class TestGetCoachProfile:

    async def _setup_db(self, mock_db, user, coach):
        """Wire two sequential execute calls: User query then Coach query."""
        user_result = MagicMock()
        user_result.scalar_one_or_none.return_value = user

        coach_result = MagicMock()
        coach_result.scalar_one_or_none.return_value = coach

        mock_db.execute.side_effect = [user_result, coach_result]

    async def test_returns_profile_dict(self, mock_db, coach_user):
        coach = make_coach()
        await self._setup_db(mock_db, coach_user, coach)

        profile = await get_coach_profile(1, mock_db)

        assert profile is not None
        assert profile["email"] == coach_user.email
        assert profile["coachID"] == coach.coachID

    async def test_returns_none_when_user_not_found(self, mock_db):
        user_result = MagicMock()
        user_result.scalar_one_or_none.return_value = None
        mock_db.execute.side_effect = [user_result]

        profile = await get_coach_profile(999, mock_db)

        assert profile is None

    async def test_returns_none_when_coach_record_missing(self, mock_db, coach_user):
        user_result = MagicMock()
        user_result.scalar_one_or_none.return_value = coach_user
        coach_result = MagicMock()
        coach_result.scalar_one_or_none.return_value = None
        mock_db.execute.side_effect = [user_result, coach_result]

        profile = await get_coach_profile(1, mock_db)

        assert profile is None

    async def test_specializations_are_split_into_list(self, mock_db, coach_user):
        coach = make_coach(specializations="yoga,pilates")
        await self._setup_db(mock_db, coach_user, coach)

        profile = await get_coach_profile(1, mock_db)

        assert profile["specializations"] == ["yoga", "pilates"]

    async def test_specializations_none_when_not_set(self, mock_db, coach_user):
        coach = make_coach(specializations=None)
        await self._setup_db(mock_db, coach_user, coach)

        profile = await get_coach_profile(1, mock_db)

        assert profile["specializations"] is None

    async def test_profile_has_all_required_keys(self, mock_db, coach_user):
        coach = make_coach()
        await self._setup_db(mock_db, coach_user, coach)

        profile = await get_coach_profile(1, mock_db)

        required_keys = {
            "userID", "coachID", "name", "email", "phone",
            "bio", "specializations", "certifications",
            "years_experience", "date_of_birth",
        }
        assert required_keys.issubset(profile.keys())


# ── update_coach_profile ──────────────────────────────────────────────────────

class TestUpdateCoachProfile:

    async def _setup_update_db(self, mock_db, user, coach):
        """
        update_coach_profile calls db.execute four times:
          1) User query (update)
          2) Coach query (update)
          3) User query (inside get_coach_profile at the end)
          4) Coach query (inside get_coach_profile at the end)
        """
        user_r = MagicMock()
        user_r.scalar_one_or_none.return_value = user
        coach_r = MagicMock()
        coach_r.scalar_one_or_none.return_value = coach

        # Called twice: once for update, once inside get_coach_profile
        mock_db.execute.side_effect = [user_r, coach_r, user_r, coach_r]

    async def test_returns_none_when_user_not_found(self, mock_db, profile_update_payload):
        user_r = MagicMock()
        user_r.scalar_one_or_none.return_value = None
        mock_db.execute.side_effect = [user_r]

        result = await update_coach_profile(999, profile_update_payload, mock_db)

        assert result is None

    async def test_returns_none_when_coach_not_found(self, mock_db, coach_user, profile_update_payload):
        user_r = MagicMock()
        user_r.scalar_one_or_none.return_value = coach_user
        coach_r = MagicMock()
        coach_r.scalar_one_or_none.return_value = None
        mock_db.execute.side_effect = [user_r, coach_r]

        result = await update_coach_profile(1, profile_update_payload, mock_db)

        assert result is None

    async def test_updates_user_name_and_phone(self, mock_db, coach_user, profile_update_payload):
        coach = make_coach()
        await self._setup_update_db(mock_db, coach_user, coach)

        await update_coach_profile(1, profile_update_payload, mock_db)

        assert coach_user.name == profile_update_payload.name
        assert coach_user.phone == profile_update_payload.phone


    async def test_partial_update_skips_none_fields(
        self, mock_db, coach_user, partial_profile_update_payload
    ):
        coach = make_coach(bio="Original bio")
        await self._setup_update_db(mock_db, coach_user, coach)

        await update_coach_profile(1, partial_profile_update_payload, mock_db)

        # bio is None in payload → should NOT be overwritten
        assert coach.bio == "Original bio"


    async def test_returns_updated_profile(self, mock_db, coach_user, profile_update_payload):
        coach = make_coach()
        await self._setup_update_db(mock_db, coach_user, coach)

        result = await update_coach_profile(1, profile_update_payload, mock_db)

        # get_coach_profile is called at the end; result should be a dict
        assert result is not None
        assert isinstance(result, dict)