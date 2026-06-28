# tests/unit/auth/conftest.py
import pytest
from datetime import datetime, timedelta , timezone
from unittest.mock import MagicMock
from test.helpers import make_user 
from app.schemas.auth.SignInRequest import SignInRequest
from app.schemas.auth.SignUpRequest import SignUpRequest
from app.schemas.auth.VerifyEmailRequest import VerifyEmailRequest
from app.schemas.auth.ResendVerficationRequest import ResendVerificationRequest
from app.schemas.auth.ForgotPasswordRequest import ForgotPasswordRequest


#user fixtures
@pytest.fixture
def verified_user():
    return make_user(is_verified=True)


@pytest.fixture
def unverified_user():
    return make_user(
        is_verified=False,
        reset_token="123456",
        reset_token_exp= datetime.now(timezone.utc) + timedelta(hours=24),
    )


@pytest.fixture
def expired_token_user():
    #already expired token
    return make_user(
        is_verified=False,
        reset_token="123456",
        reset_token_exp= datetime.now(timezone.utc) - timedelta(hours=1),  #one hour ago
    )


@pytest.fixture
def client_user():
    return make_user(role="client")


@pytest.fixture
def coach_user():
    return make_user(role="coach", userID=2, email="coach@example.com")


@pytest.fixture
def admin_user():
    return make_user(role="admin", userID=3, email="admin@example.com")


# ── Payload fixtures ───────────────────────────────────────────────────────────

@pytest.fixture
def signin_payload():
    return SignInRequest(email="test@example.com", password="Password123!")


@pytest.fixture
def signup_payload():
    role = MagicMock()
    role.value = "client"
    payload = MagicMock(spec=SignUpRequest)
    payload.email = "newuser@example.com"
    payload.name = "New User"
    payload.password = "Password123!"
    payload.phone = "01234567890"
    payload.role = role
    return payload


@pytest.fixture
def verify_email_payload():
    return VerifyEmailRequest(email="test@example.com", code="123456")


@pytest.fixture
def resend_payload():
    return ResendVerificationRequest(email="test@example.com")


@pytest.fixture
def forgot_password_payload():
    return ForgotPasswordRequest(email="test@example.com")