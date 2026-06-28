import pytest
from fastapi import HTTPException
from unittest.mock import MagicMock, patch, ANY
from test.helpers import make_user, mock_execute_returning
from app.services.auth.auth_service import (
    signup_user,
    signin_user,
    verify_email,
    resend_verification,
    forgot_password,
    detect_role,
)



# detect_role

class TestDetectRole:

    async def test_returns_client(self, mock_db):
        # First execute call (Client table) returns a hit
        client_result = MagicMock()
        client_result.scalar_one_or_none.return_value = MagicMock()
        mock_db.execute.return_value = client_result

        role = await detect_role(1, mock_db)
        assert role == "client"

    async def test_returns_coach(self, mock_db):
        # First call (Client) → None, second call (Coach) → hit
        no_result = MagicMock()
        no_result.scalar_one_or_none.return_value = None
        coach_result = MagicMock()
        coach_result.scalar_one_or_none.return_value = MagicMock()
        mock_db.execute.side_effect = [no_result, coach_result]

        role = await detect_role(1, mock_db)
        assert role == "coach"

    async def test_returns_admin(self, mock_db):
        # Client → None, Coach → None, Admin → hit
        no_result = MagicMock()
        no_result.scalar_one_or_none.return_value = None
        admin_result = MagicMock()
        admin_result.scalar_one_or_none.return_value = MagicMock()
        mock_db.execute.side_effect = [no_result, no_result, admin_result]

        role = await detect_role(1, mock_db)
        assert role == "admin"

    async def test_raises_if_no_role(self, mock_db):
        # All three tables return None
        no_result = MagicMock()
        no_result.scalar_one_or_none.return_value = None
        mock_db.execute.side_effect = [no_result, no_result, no_result]

        with pytest.raises(HTTPException) as exc:
            await detect_role(1, mock_db)
        assert exc.value.status_code == 400




# signup_user

class TestSignupUser:

    async def test_raises_if_email_already_registered(self, mock_db, signup_payload, verified_user):
        mock_execute_returning(mock_db, verified_user)  # email exists in DB

        with pytest.raises(HTTPException) as exc:
            await signup_user(signup_payload, mock_db)
        assert exc.value.status_code == 400
        assert "already registered" in exc.value.detail

    async def test_creates_user_successfully(self, mock_db, signup_payload, mock_emails):
        mock_execute_returning(mock_db, None)  # email not taken

        await signup_user(signup_payload, mock_db)

        mock_db.add.assert_called()     # User was added
        mock_db.commit.assert_called_once()
        mock_db.refresh.assert_called_once()

    async def test_sends_verification_email(self, mock_db, signup_payload, mock_emails):
        mock_execute_returning(mock_db, None)

        await signup_user(signup_payload, mock_db)

        mock_emails["verify"].assert_called_once()

    async def test_adds_client_role_row(self, mock_db, signup_payload):
        mock_execute_returning(mock_db, None)
        signup_payload.role.value = "client"

        await signup_user(signup_payload, mock_db)

        # db.add called at least twice: once for User, once for Client
        assert mock_db.add.call_count >= 2

    async def test_rollback_on_exception(self, mock_db, signup_payload):
        mock_execute_returning(mock_db, None)
        mock_db.flush.side_effect = Exception("DB error")

        with pytest.raises(Exception):
            await signup_user(signup_payload, mock_db)

        mock_db.rollback.assert_called_once()



# signin_user

class TestSigninUser:

    async def test_raises_if_user_not_found(self, mock_db, signin_payload):
        mock_execute_returning(mock_db, None)

        with pytest.raises(HTTPException) as exc:
            await signin_user(signin_payload, mock_db)
        assert exc.value.status_code == 401

    async def test_raises_if_wrong_password(self, mock_db, signin_payload, verified_user):
        mock_execute_returning(mock_db, verified_user)

        with patch("app.services.auth.auth_service.bcrypt.checkpw", return_value=False):
            with pytest.raises(HTTPException) as exc:
                await signin_user(signin_payload, mock_db)
        assert exc.value.status_code == 401

    async def test_raises_if_not_verified(self, mock_db, signin_payload):
        user = make_user(is_verified=False)
        # Use a real bcrypt hash so password check passes
        import bcrypt
        user.password = bcrypt.hashpw(b"Password123!", bcrypt.gensalt()).decode()
        mock_execute_returning(mock_db, user)

        with pytest.raises(HTTPException) as exc:
            await signin_user(signin_payload, mock_db)
        assert exc.value.status_code == 403


    async def test_returns_token_on_success(self, mock_db, signin_payload):
        import bcrypt
        user = make_user(is_verified=True)
        user.password = bcrypt.hashpw(b"Password123!", bcrypt.gensalt()).decode()
        mock_execute_returning(mock_db, user)

        # detect_role will make more db.execute calls → mock them to return client
        client_result = MagicMock()
        client_result.scalar_one_or_none.return_value = MagicMock()

        # First execute = user lookup (already set), subsequent = role detection
        original_execute = mock_db.execute.return_value
        mock_db.execute.side_effect = [original_execute, client_result]

        response = await signin_user(signin_payload, mock_db)

        assert response.access_token is not None
        assert response.token_type == "bearer"
        assert response.role == "client"



# verify_email

class TestVerifyEmail:

    async def test_raises_if_user_not_found(self, mock_db, verify_email_payload):
        mock_execute_returning(mock_db, None)

        with pytest.raises(HTTPException) as exc:
            await verify_email(verify_email_payload, mock_db)
        assert exc.value.status_code == 404

    async def test_returns_already_verified_message(self, mock_db, verify_email_payload, verified_user):
        mock_execute_returning(mock_db, verified_user)

        result = await verify_email(verify_email_payload, mock_db)

        assert result["message"] == "Email already verified"
        mock_db.commit.assert_not_called()

    # test/unit/auth/test_auth_service.py

    async def test_raises_if_wrong_password(self, mock_db, signin_payload, verified_user): 
        mock_execute_returning(mock_db, verified_user)
        with patch("app.services.auth.auth_service.bcrypt.checkpw", return_value=False):
            with pytest.raises(HTTPException) as exc:
                await signin_user(signin_payload, mock_db)
        assert exc.value.status_code == 401

    async def test_raises_if_token_expired(self, mock_db, verify_email_payload, expired_token_user):
        mock_execute_returning(mock_db, expired_token_user)

        with pytest.raises(HTTPException) as exc:
            await verify_email(verify_email_payload, mock_db)
        assert exc.value.status_code == 400
        assert "expired" in exc.value.detail

    async def test_verifies_successfully(self, mock_db, verify_email_payload, unverified_user):
        mock_execute_returning(mock_db, unverified_user)

        result = await verify_email(verify_email_payload, mock_db)

        assert result["message"] == "Email verified successfully! You can now sign in."
        assert unverified_user.is_verified is True
        assert unverified_user.reset_token is None
        mock_db.commit.assert_called_once()



# resend_verification

class TestResendVerification:

    async def test_raises_if_email_not_found(self, mock_db, resend_payload):
        mock_execute_returning(mock_db, None)

        with pytest.raises(HTTPException) as exc:
            await resend_verification(resend_payload, mock_db)
        assert exc.value.status_code == 404

    async def test_raises_if_already_verified(self, mock_db, resend_payload, verified_user):
        mock_execute_returning(mock_db, verified_user)

        with pytest.raises(HTTPException) as exc:
            await resend_verification(resend_payload, mock_db)
        assert exc.value.status_code == 400
        assert "already verified" in exc.value.detail

    async def test_resends_successfully(self, mock_db, resend_payload, unverified_user, mock_emails):
        mock_execute_returning(mock_db, unverified_user)

        result = await resend_verification(resend_payload, mock_db)

        assert result["message"] == "Verification code resent successfully"
        mock_db.commit.assert_called_once()
        mock_emails["verify"].assert_called_once_with(unverified_user.email, ANY)

    async def test_updates_token_on_resend(self, mock_db, resend_payload, unverified_user):
        old_token = unverified_user.reset_token
        mock_execute_returning(mock_db, unverified_user)

        await resend_verification(resend_payload, mock_db)

        # Token should have been replaced with a new 6-digit code
        assert unverified_user.reset_token != old_token
        assert len(unverified_user.reset_token) == 6


# forgot_password

class TestForgotPassword:

    async def test_raises_if_email_not_found(self, mock_db, forgot_password_payload):
        mock_execute_returning(mock_db, None)

        with pytest.raises(HTTPException) as exc:
            await forgot_password(forgot_password_payload, mock_db)
        assert exc.value.status_code == 404

    async def test_sends_reset_email(self, mock_db, forgot_password_payload, verified_user, mock_emails):
        mock_execute_returning(mock_db, verified_user)

        await forgot_password(forgot_password_payload, mock_db)

        mock_emails["reset"].assert_called_once_with(verified_user.email, ANY)

    async def test_sets_reset_token(self, mock_db, forgot_password_payload, verified_user):
        mock_execute_returning(mock_db, verified_user)

        await forgot_password(forgot_password_payload, mock_db)

        assert verified_user.reset_token is not None
        assert len(verified_user.reset_token) == 6
        mock_db.commit.assert_called_once()

    async def test_returns_success_message(self, mock_db, forgot_password_payload, verified_user):
        mock_execute_returning(mock_db, verified_user)

        result = await forgot_password(forgot_password_payload, mock_db)

        assert result["message"] == "A reset code has been sent."