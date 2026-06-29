from datetime import date, timedelta
from unittest.mock import MagicMock
from app.models.gym_clients_membership import ClientMembershipStatus

def make_user(**overrides):
    user = MagicMock()
    user.userID = 1
    user.email = "test@example.com"
    user.name = "Test User"
    user.password = "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/HS.iK8i"
    user.role = "client"
    user.phone = "01234567890"
    user.is_verified = True
    user.reset_token = None
    user.reset_token_exp = None
    for key, value in overrides.items():
        setattr(user, key, value)
    return user

def mock_execute_returning(db, value):
    result = MagicMock()
    result.scalar_one_or_none.return_value = value
    db.execute.return_value = result

def scalar_one_or_none_result(value):
    r = MagicMock()
    r.scalar_one_or_none.return_value = value
    return r

def scalars_all_result(values):
    r = MagicMock()
    r.scalars.return_value.all.return_value = values
    return r

def make_membership_row(status="active"):
    membership = MagicMock()
    membership.status.value = status
    membership.hire_date = None
    coach = MagicMock()
    coach.coachID = 1
    user = MagicMock()
    user.userID = 10
    user.name = "Coach A"
    user.email = "coach@example.com"
    user.phone = "01000000000"
    return membership, coach, user


def make_invitation(email="coach@example.com"):
    inv = MagicMock()
    inv.id = 99
    inv.email = email
    inv.sent_at = None
    return inv

def make_invite_body(email="client@example.com", subscription_type="monthly", months=1, price=100):
    body = MagicMock()
    body.email = email
    body.subscription_type = subscription_type
    body.subscription_months = months
    body.subscription_price = price
    return body

def make_client_membership(sub_end=None):
    m = MagicMock()
    m.status = ClientMembershipStatus.active
    m.subscription_end = sub_end or (date.today() + timedelta(days=30))
    m.clientID = 1
    m.gymID = 5
    return m

def scalar_one_result(value):
    r = MagicMock()
    r.scalar_one.return_value = value
    return r


def all_result(rows):
    r = MagicMock()
    r.all.return_value = rows
    return r