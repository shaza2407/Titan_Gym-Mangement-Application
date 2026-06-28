import pytest
from unittest.mock import MagicMock, AsyncMock
from test.helpers import make_user


@pytest.fixture
def mock_client():
    client = MagicMock()
    client.clientID = 1
    client.userID = 10
    return client