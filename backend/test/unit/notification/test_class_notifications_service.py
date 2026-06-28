import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from app.services.notifications.class_notifications import notify_class_reminder


SESSION_ID = 42
CLIENT_ID = 1
CLASS_TITLE = "Yoga"


def make_db_with_client(client):
    """Build a fake async db session that returns the given client."""
    db = AsyncMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = client
    db.execute.return_value = result
    return db


async def fake_get_session(db):
    """Mimics `async for db in get_session()` — yields the db once."""
    yield db


# notify_class_reminder

class TestNotifyClassReminder:

    async def test_does_nothing_if_client_not_found(self):
        db = make_db_with_client(None)

        with patch("app.services.notifications.class_notifications.get_session", return_value=fake_get_session(db)), \
             patch("app.services.notifications.class_notifications.save_notification", new_callable=AsyncMock) as mock_save, \
             patch("app.services.notifications.class_notifications.send_push_notification", new_callable=AsyncMock) as mock_push:

            await notify_class_reminder(SESSION_ID, CLIENT_ID, CLASS_TITLE)

            mock_save.assert_not_called()
            mock_push.assert_not_called()

    async def test_saves_notification_when_client_found(self, mock_client):
        db = make_db_with_client(mock_client)

        with patch("app.services.notifications.class_notifications.get_session", return_value=fake_get_session(db)), \
             patch("app.services.notifications.class_notifications.save_notification", new_callable=AsyncMock) as mock_save, \
             patch("app.services.notifications.class_notifications.send_push_notification", new_callable=AsyncMock):

            await notify_class_reminder(SESSION_ID, CLIENT_ID, CLASS_TITLE)

            mock_save.assert_called_once()

    async def test_sends_push_notification_when_client_found(self, mock_client):
        db = make_db_with_client(mock_client)

        with patch("app.services.notifications.class_notifications.get_session", return_value=fake_get_session(db)), \
             patch("app.services.notifications.class_notifications.save_notification", new_callable=AsyncMock), \
             patch("app.services.notifications.class_notifications.send_push_notification", new_callable=AsyncMock) as mock_push:

            await notify_class_reminder(SESSION_ID, CLIENT_ID, CLASS_TITLE)

            mock_push.assert_called_once()

    async def test_passes_correct_user_id(self, mock_client):
        db = make_db_with_client(mock_client)

        with patch("app.services.notifications.class_notifications.get_session", return_value=fake_get_session(db)), \
             patch("app.services.notifications.class_notifications.save_notification", new_callable=AsyncMock) as mock_save, \
             patch("app.services.notifications.class_notifications.send_push_notification", new_callable=AsyncMock):

            await notify_class_reminder(SESSION_ID, CLIENT_ID, CLASS_TITLE)

            call_kwargs = mock_save.call_args.kwargs
            assert call_kwargs["user_id"] == mock_client.userID

    async def test_passes_correct_session_id_in_data(self, mock_client):
        db = make_db_with_client(mock_client)

        with patch("app.services.notifications.class_notifications.get_session", return_value=fake_get_session(db)), \
             patch("app.services.notifications.class_notifications.save_notification", new_callable=AsyncMock) as mock_save, \
             patch("app.services.notifications.class_notifications.send_push_notification", new_callable=AsyncMock):

            await notify_class_reminder(SESSION_ID, CLIENT_ID, CLASS_TITLE)

            call_kwargs = mock_save.call_args.kwargs
            assert call_kwargs["data"]["session_id"] == str(SESSION_ID)

    async def test_includes_class_title_in_body(self, mock_client):
        db = make_db_with_client(mock_client)

        with patch("app.services.notifications.class_notifications.get_session", return_value=fake_get_session(db)), \
             patch("app.services.notifications.class_notifications.save_notification", new_callable=AsyncMock) as mock_save, \
             patch("app.services.notifications.class_notifications.send_push_notification", new_callable=AsyncMock):

            await notify_class_reminder(SESSION_ID, CLIENT_ID, "Yoga")

            call_kwargs = mock_save.call_args.kwargs
            assert "Yoga" in call_kwargs["body"]

    async def test_notification_type_is_class_reminder(self, mock_client):
        db = make_db_with_client(mock_client)

        with patch("app.services.notifications.class_notifications.get_session", return_value=fake_get_session(db)), \
             patch("app.services.notifications.class_notifications.save_notification", new_callable=AsyncMock) as mock_save, \
             patch("app.services.notifications.class_notifications.send_push_notification", new_callable=AsyncMock):

            await notify_class_reminder(SESSION_ID, CLIENT_ID, CLASS_TITLE)

            call_kwargs = mock_save.call_args.kwargs
            assert call_kwargs["type"] == "class-reminder"