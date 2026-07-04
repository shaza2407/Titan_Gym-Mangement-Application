import pytest
from unittest.mock import AsyncMock, patch
from fastapi import HTTPException

from app.services.client.achievements import (
    get_client_achievements_service,
    recalculate_client_achievements_service,
)
from app.models.client import Client


# ── Helpers ───────────────────────────────────────────────────────────────────

def _make_client(client_id: int = 1, user_id: int = 1) -> Client:
    c = Client()
    c.clientID = client_id
    c.userID = user_id
    return c


def _make_achievements(n: int) -> list:
    return [{"key": f"achv_{i}"} for i in range(n)]


PATCH_GET_CLIENT = "app.services.client.achievements.get_client_by_user_id"
PATCH_GET_ACHIEVEMENTS = "app.services.client.achievements.achievement_engine.get_client_achievements"
PATCH_ON_CHECKIN = "app.services.client.achievements.achievement_engine.on_checkin"
PATCH_ON_CLASS = "app.services.client.achievements.achievement_engine.on_class_attended"
PATCH_ON_PLAN = "app.services.client.achievements.achievement_engine.on_plan_completed"
PATCH_ON_WORKOUT = "app.services.client.achievements.achievement_engine.on_workout_logged"
PATCH_ON_PLAN_GEN = "app.services.client.achievements.achievement_engine.on_plan_generated"


# ── A2) caller is not a client -> propagated 403 ───────────────────────────────

@pytest.mark.asyncio
async def test_get_client_achievements_service_not_found():
    db = AsyncMock()

    with patch(PATCH_GET_CLIENT, new_callable=AsyncMock) as mock_get_client:
        mock_get_client.side_effect = HTTPException(status_code=403, detail="Only clients can view achievements.")

        with pytest.raises(HTTPException) as exc_info:
            await get_client_achievements_service(user_id=10, db=db)

        assert exc_info.value.status_code == 403
        assert exc_info.value.detail == "Only clients can view achievements."


# ── Success Tests ─────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_get_client_achievements_service_success():
    db = AsyncMock()
    mock_client = _make_client(client_id=3, user_id=30)
    mock_achievements = _make_achievements(2)

    with patch(PATCH_GET_CLIENT, new_callable=AsyncMock) as mock_get_client, \
         patch(PATCH_GET_ACHIEVEMENTS, new_callable=AsyncMock) as mock_get_achievements:

        mock_get_client.return_value = mock_client
        mock_get_achievements.return_value = mock_achievements

        result = await get_client_achievements_service(user_id=30, db=db)

        mock_get_client.assert_awaited_once_with(30, db, detail="Only clients can view achievements.")
        mock_get_achievements.assert_awaited_once_with(3, db)
        assert result == mock_achievements

@pytest.mark.asyncio
async def test_recalculate_client_achievements_service_success():
    db = AsyncMock()
    mock_client = _make_client(client_id=5, user_id=50)
    mock_achievements = _make_achievements(3)

    with patch(PATCH_GET_CLIENT, new_callable=AsyncMock) as mock_get_client, \
         patch(PATCH_ON_CHECKIN, new_callable=AsyncMock) as mock_on_checkin, \
         patch(PATCH_ON_CLASS, new_callable=AsyncMock) as mock_on_class, \
         patch(PATCH_GET_ACHIEVEMENTS, new_callable=AsyncMock) as mock_get_achievements:

        mock_get_client.return_value = mock_client
        mock_get_achievements.return_value = mock_achievements

        result = await recalculate_client_achievements_service(user_id=50, db=db)

        mock_get_client.assert_awaited_once_with(50, db, detail="Only clients can view achievements.")
        mock_on_checkin.assert_awaited_once_with(5, db)
        mock_on_class.assert_awaited_once_with(5, db)
        mock_get_achievements.assert_awaited_once_with(5, db)

        assert result == mock_achievements

# ── D1) Downstream engine failure propagates and short-circuits the chain ─────

@pytest.mark.asyncio
async def test_recalculate_client_achievements_service_engine_failure_propagates():
    db = AsyncMock()
    mock_client = _make_client(client_id=6, user_id=60)

    with patch(PATCH_GET_CLIENT, new_callable=AsyncMock) as mock_get_client, \
         patch(PATCH_ON_CHECKIN, new_callable=AsyncMock) as mock_on_checkin, \
         patch(PATCH_ON_CLASS, new_callable=AsyncMock) as mock_on_class, \
         patch(PATCH_ON_PLAN, new_callable=AsyncMock) as mock_on_plan, \
         patch(PATCH_ON_WORKOUT, new_callable=AsyncMock) as mock_on_workout, \
         patch(PATCH_ON_PLAN_GEN, new_callable=AsyncMock) as mock_on_plan_gen:

        mock_get_client.return_value = mock_client
        mock_on_checkin.side_effect = RuntimeError("engine boom")

        with pytest.raises(RuntimeError, match="engine boom"):
            await recalculate_client_achievements_service(user_id=60, db=db)

        mock_on_checkin.assert_awaited_once_with(6, db)
        # on_checkin failed first, so the later handlers in the chain never fire
        mock_on_class.assert_not_called()
        mock_on_plan.assert_not_called()
        mock_on_workout.assert_not_called()
        mock_on_plan_gen.assert_not_called()
