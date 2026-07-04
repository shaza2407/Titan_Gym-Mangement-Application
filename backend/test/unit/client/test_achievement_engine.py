import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from datetime import date, datetime, timedelta
from typing import List

from app.services.client.achievement_engine import AchievementEngine
from app.models.achievement import Achievement
from app.models.client_achievement import ClientAchievement
from app.models.attendance import Attendance

@pytest.fixture
def engine():
    return AchievementEngine()

def _mock_db():
    db = AsyncMock()
    db.add = MagicMock()
    return db

def _make_achievement(aid: int, target: int, chain_key: str = "gym_rat"):
    a = Achievement()
    a.achievementID = aid
    a.target = target
    a.chain_key = chain_key
    a.key = f"{chain_key}_{target}"
    a.name = f"Badge {target}"
    a.description = "Test"
    return a

def _make_client_achievement(aid: int, current_value: int, target: int, is_unlocked: bool = False):
    ca = ClientAchievement()
    ca.achievementID = aid
    ca.current_value = current_value
    ca.best_value = current_value
    ca.is_unlocked = is_unlocked
    return ca

@pytest.mark.asyncio
async def test_apply_progress_unlocks_and_creates_next_level(engine):
    db = _mock_db()
    
    # 2 levels: target 10, target 25
    lvl1 = _make_achievement(1, 10)
    lvl2 = _make_achievement(2, 25)
    
    # User currently has ca for lvl1, not unlocked yet, current=8
    ca1 = _make_client_achievement(1, 8, 10, False)
    
    # Mock queries: 
    # 1. get levels
    # 2. get ca for lvl 1
    # 3. get ca for lvl 2
    mock_result_levels = MagicMock()
    mock_result_levels.scalars().all.return_value = [lvl1, lvl2]
    
    mock_result_ca1 = MagicMock()
    mock_result_ca1.scalar_one_or_none.return_value = ca1
    
    mock_result_ca2 = MagicMock()
    mock_result_ca2.scalar_one_or_none.return_value = None
    
    db.execute.side_effect = [
        mock_result_levels,
        mock_result_ca1,
        mock_result_ca2,
    ]
    
    with patch.object(engine, "_notify_badge_unlocked", new_callable=AsyncMock) as mock_notify:
        await engine._apply_progress("gym_rat", client_id=1, raw_value=12, db=db)
        
        # level 1 should be unlocked
        assert ca1.is_unlocked is True
        assert ca1.current_value == 10  # Capped at target
        
        # level 2 should be created
        db.add.assert_called_once()
        ca2_added = db.add.call_args[0][0]
        assert ca2_added.achievementID == 2
        assert ca2_added.current_value == 12
        assert ca2_added.is_unlocked is False
        
        mock_notify.assert_awaited_once_with(1, lvl1, db)

@pytest.mark.asyncio
async def test_calculate_current_streak(engine):
    db = _mock_db()
    
    # Streak includes today, yesterday, but misses the day before
    today = date.today()
    dates = [
        today,
        today - timedelta(days=1),
        today - timedelta(days=3), # Missed day 2
    ]
    
    mock_result = MagicMock()
    mock_result.scalars().all.return_value = dates
    db.execute.return_value = mock_result
    
    streak = await engine._calculate_current_streak(client_id=1, db=db)
    assert streak == 2
