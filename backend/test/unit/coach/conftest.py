# tests/unit/coach/conftest.py
import pytest
from datetime import date, time, timedelta
from unittest.mock import MagicMock, patch, AsyncMock

from test.unit.coach.helpers import (
    make_coach,
    make_session,
    make_gym,
    make_gym_coach_membership,
    make_class_request,
    make_announcement,
    make_create_class_payload,
    make_profile_update_payload,
)


# ── Coach / User fixtures ─────────────────────────────────────────────────────

@pytest.fixture
def coach():
    return make_coach()


@pytest.fixture
def coach_user():
    """User-row mock for the coach (as returned by the User table)."""
    user = MagicMock()
    user.userID = 1
    user.name = "Test Coach"
    user.email = "coach@example.com"
    user.phone = "01234567890"
    user.role = "coach"
    return user


@pytest.fixture
def coach_no_bio():
    return make_coach(bio=None, specializations=None, certifications=None)


# ── Session (ClassSession) fixtures ───────────────────────────────────────────

@pytest.fixture
def recurring_session():
    """A recurring weekly session on Monday."""
    return make_session(is_recurring=True, day_of_week="monday", date=None)


@pytest.fixture
def one_time_session():
    """A one-time session scheduled for today."""
    return make_session(is_recurring=False, day_of_week=None, date=date.today())


@pytest.fixture
def future_one_time_session():
    """A one-time session scheduled 5 days from now."""
    return make_session(
        is_recurring=False,
        day_of_week=None,
        date=date.today() + timedelta(days=5),
    )


@pytest.fixture
def past_one_time_session():
    """A one-time session that already passed — should be filtered out."""
    return make_session(
        is_recurring=False,
        day_of_week=None,
        date=date.today() - timedelta(days=3),
    )


# ── Gym / Membership fixtures ─────────────────────────────────────────────────

@pytest.fixture
def gym():
    return make_gym()


@pytest.fixture
def gym_membership():
    return make_gym_coach_membership()


# ── Class Request fixtures ────────────────────────────────────────────────────

@pytest.fixture
def pending_request():
    r = make_class_request()
    r.status.value = "pending"
    return r


@pytest.fixture
def approved_request():
    r = make_class_request(id=2)
    r.status.value = "approved"
    return r


# ── Announcement fixtures ─────────────────────────────────────────────────────

@pytest.fixture
def announcement_coaches_only():
    return make_announcement(reciever="Coaches only")


@pytest.fixture
def announcement_all():
    return make_announcement(id=2, reciever="Clients and Coaches")


# ── Payload fixtures ──────────────────────────────────────────────────────────

@pytest.fixture
def create_class_payload():
    return make_create_class_payload()


@pytest.fixture
def create_one_time_class_payload():
    return make_create_class_payload(
        is_recurring=False,
        day_of_week=None,
        requested_date=date.today() + timedelta(days=3),
    )


@pytest.fixture
def profile_update_payload():
    return make_profile_update_payload()


@pytest.fixture
def partial_profile_update_payload():
    """Only name and phone are set; everything else is None."""
    return make_profile_update_payload(
        bio=None,
        specializations=None,
        certifications=None,
        years_experience=None,
        date_of_birth=None,
    )


# ── Notification patch ────────────────────────────────────────────────────────

@pytest.fixture(autouse=True)
def mock_notifications():
    """Suppress all outgoing notifications so tests don't need a real DB chain."""
    with patch(
        "app.services.coach.coach_schedule.notify_admin",
        new_callable=AsyncMock,
    ) as mock_admin:
        yield {"admin": mock_admin}