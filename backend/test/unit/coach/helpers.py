# tests/unit/coach/helpers.py

from datetime import date, time
from unittest.mock import MagicMock



def make_coach(**overrides):
    coach = MagicMock()
    coach.coachID = 6
    coach.userID = 1
    coach.bio = "Experienced fitness coach"
    coach.specializations = "yoga,pilates"
    coach.certifications = ""
    coach.years_experience = 5
    coach.date_of_birth = date(1990, 1, 1)
    for key, value in overrides.items():
        setattr(coach, key, value)
    return coach


def make_session(**overrides):
    """Factory for ClassSession mock objects."""
    s = MagicMock()
    s.id = 1
    s.coach_id = 6
    s.gymID = 100
    s.title = "Morning Yoga"
    s.is_recurring = True
    s.day_of_week = "monday"
    s.date = None
    s.start_time = time(9, 0)
    s.duration = 60
    s.max_clients = 20
    for key, value in overrides.items():
        setattr(s, key, value)
    return s


def make_gym(**overrides):
    gym = MagicMock()
    gym.gymID = 100
    gym.gymName = "Test Gym"
    gym.location = "123 Main St, Cairo"
    for key, value in overrides.items():
        setattr(gym, key, value)
    return gym


def make_gym_coach_membership(**overrides):
    m = MagicMock()
    m.coachID = 6
    m.gymID = 100
    m.status = MagicMock()
    m.status.value = "active"
    for key, value in overrides.items():
        setattr(m, key, value)
    return m


def make_class_request(**overrides):
    r = MagicMock()
    r.id = 1
    r.coach_id = 6
    r.gymID = 100
    r.class_name = "Pilates"
    r.is_recurring = True
    r.day_of_week = "monday"
    r.requested_date = None
    r.requested_time = time(10, 0)
    r.duration = 60
    r.max_capacity = 15
    r.reason_for_request = ""
    r.status = MagicMock()
    r.status.value = "pending"
    r.created_at = date.today()
    for key, value in overrides.items():
        setattr(r, key, value)
    return r


def make_announcement(**overrides):
    a = MagicMock()
    a.announce_id = 1
    a.gymID = 100
    a.title = "Gym Closed Monday"
    a.content = "The gym will be closed for maintenance."
    a.reciever = "Clients and Coaches"
    a.created_at = MagicMock()
    a.created_at.isoformat.return_value = "2025-06-01T10:00:00"
    for key, value in overrides.items():
        setattr(a, key, value)
    return a


def make_create_class_payload(**overrides):
    payload = MagicMock()
    payload.class_name = "Pilates"
    payload.is_recurring = True
    payload.day_of_week = "monday"
    payload.requested_date = None
    payload.requested_time = time(10, 0)
    payload.duration = 60
    payload.max_capacity = 15
    payload.reason = ""
    for key, value in overrides.items():
        setattr(payload, key, value)
    return payload


def make_profile_update_payload(**overrides):
    payload = MagicMock()
    payload.name = "Updated Name"
    payload.phone = "01111111111"
    payload.bio = "Updated bio"
    payload.specializations = ["yoga", "pilates"]
    payload.certifications = "ACE"
    payload.years_experience = 7
    payload.date_of_birth = date(1990, 5, 15)
    for key, value in overrides.items():
        setattr(payload, key, value)
    return payload


# ── DB mock helpers ───────────────────────────────────────────────────────────

def mock_execute_returning(db, value):
    """Make db.execute(...).scalar_one_or_none() return value."""
    result = MagicMock()
    result.scalar_one_or_none.return_value = value
    db.execute.return_value = result


def mock_execute_scalars(db, values: list):
    """Make db.execute(...).scalars().all() return a list."""
    scalars = MagicMock()
    scalars.all.return_value = values
    result = MagicMock()
    result.scalars.return_value = scalars
    db.execute.return_value = result


def mock_execute_scalar_value(db, value):
    """Make db.scalar(...) return value directly (used for func.count etc.)."""
    db.scalar.return_value = value


def mock_execute_side_effects(db, effects: list):
    """
    Provide a sequence of return values for successive db.execute() calls.
    Each element can be:
      - a single value  → wrapped as scalar_one_or_none result
      - a list          → wrapped as scalars().all() result
      - a MagicMock     → used as-is (caller built it already)
    """
    results = []
    for effect in effects:
        if isinstance(effect, MagicMock):
            results.append(effect)
        elif isinstance(effect, list):
            scalars = MagicMock()
            scalars.all.return_value = effect
            r = MagicMock()
            r.scalars.return_value = scalars
            results.append(r)
        else:
            r = MagicMock()
            r.scalar_one_or_none.return_value = effect
            r.scalar.return_value = effect
            results.append(r)
    db.execute.side_effect = results