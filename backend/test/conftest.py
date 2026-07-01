# tests/conftest.py
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
# from test.helpers import make_user, mock_execute_returning 

@pytest.fixture
def mock_db():
    db = AsyncMock()
    db.add = MagicMock()
    db.flush = AsyncMock()
    db.commit = AsyncMock()
    db.rollback = AsyncMock()
    db.refresh = AsyncMock()
    return db

@pytest.fixture(autouse=True)
def mock_emails():
    with patch("app.services.auth.auth_service.send_verification_email", new_callable=AsyncMock) as mock_verify, \
         patch("app.services.auth.auth_service.send_reset_email", new_callable=AsyncMock) as mock_reset:
        yield {"verify": mock_verify, "reset": mock_reset}