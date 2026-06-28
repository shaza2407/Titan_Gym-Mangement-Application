import pytest
from unittest.mock import MagicMock
from test.helpers import make_user


@pytest.fixture
def admin_user():
    return make_user(role="admin", userID=1, name="Admin User", email="admin@example.com", phone="01234567890")


@pytest.fixture
def mock_admin():
    admin = MagicMock()
    admin.adminID = 10
    admin.userID = 1
    return admin


@pytest.fixture
def mock_admin_profile_update():
    data = MagicMock()
    data.name = "Updated Name"
    data.phone = "09876543210"
    return data


@pytest.fixture
def mock_announcement():
    announcement = MagicMock()
    announcement.announce_id = 1
    announcement.gymID = 5
    announcement.title = "Test Announcement"
    announcement.content = "Test Content"
    announcement.reciever = "Clients only"
    return announcement


@pytest.fixture
def make_announcement_payload():
    """Factory — call with reciever = to test different receiver types."""
    def _make(reciever="Clients only"):
        payload = MagicMock()
        payload.title = "Test Title"
        payload.content = "Test Content"
        payload.reciever = reciever
        return payload
    return _make


@pytest.fixture
def mock_gym():
    gym = MagicMock()
    gym.gymID = 5
    gym.gymName = "Titan Gym"
    gym.adminID = 10
    gym.machine_inventory = []
    return gym


@pytest.fixture
def mock_gym_create():
    data = MagicMock()
    data.model_dump.return_value = {
        "gymName": "Titan Gym",
        "location": "Cairo",
        "machines": [
            {"machineName": "Treadmill", "machineType": "Cardio", "quantity": 3}
        ],
    }
    return data


@pytest.fixture
def mock_gym_update():
    data = MagicMock()
    data.model_dump.return_value = {"gymName": "Updated Gym"}
    return data