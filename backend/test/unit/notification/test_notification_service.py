# test/unit/notification/test_notification_service.py
import pytest
from unittest.mock import MagicMock, AsyncMock
from app.services.notifications.notification_service import NotificationService


USER_ID = 1
NOTIFICATION_ID = 10
TOKEN = "fcm-token-abc123"


def scalar_result(value):
    r = MagicMock()
    r.scalar.return_value = value
    return r


def scalars_all_result(values):
    r = MagicMock()
    r.scalars.return_value.all.return_value = values
    return r


def rowcount_result(count):
    r = MagicMock()
    r.rowcount = count
    return r



# get_notifications

class TestGetNotifications:

    async def test_returns_notifications(self, mock_db):
        notification = MagicMock()
        mock_db.execute.return_value = scalars_all_result([notification])

        result = await NotificationService.get_notifications(USER_ID, mock_db)

        assert len(result) == 1
        assert result[0] == notification

    async def test_returns_empty_list_when_none(self, mock_db):
        mock_db.execute.return_value = scalars_all_result([])

        result = await NotificationService.get_notifications(USER_ID, mock_db)

        assert result == []

    async def test_returns_multiple_notifications(self, mock_db):
        notifications = [MagicMock(), MagicMock(), MagicMock()]
        mock_db.execute.return_value = scalars_all_result(notifications)

        result = await NotificationService.get_notifications(USER_ID, mock_db)

        assert len(result) == 3



# get_unread_count

class TestGetUnreadCount:

    async def test_returns_count(self, mock_db):
        mock_db.execute.return_value = scalar_result(5)

        result = await NotificationService.get_unread_count(USER_ID, mock_db)

        assert result == 5

    async def test_returns_zero_when_none(self, mock_db):
        mock_db.execute.return_value = scalar_result(0)

        result = await NotificationService.get_unread_count(USER_ID, mock_db)

        assert result == 0



# mark_as_read

class TestMarkAsRead:

    async def test_returns_true_when_deleted(self, mock_db):
        mock_db.execute.return_value = rowcount_result(1)

        result = await NotificationService.mark_as_read(NOTIFICATION_ID, mock_db)

        assert result is True
        mock_db.commit.assert_called_once()

    async def test_returns_false_when_not_found(self, mock_db):
        mock_db.execute.return_value = rowcount_result(0)

        result = await NotificationService.mark_as_read(NOTIFICATION_ID, mock_db)

        assert result is False

    async def test_commits_after_delete(self, mock_db):
        mock_db.execute.return_value = rowcount_result(1)

        await NotificationService.mark_as_read(NOTIFICATION_ID, mock_db)

        mock_db.commit.assert_called_once()




# mark_all_read

class TestMarkAllRead:

    async def test_deletes_all_user_notifications(self, mock_db):
        mock_db.execute.return_value = MagicMock()

        await NotificationService.mark_all_read(USER_ID, mock_db)

        mock_db.execute.assert_called_once()
        mock_db.commit.assert_called_once()

    async def test_commits_after_delete(self, mock_db):
        mock_db.execute.return_value = MagicMock()

        await NotificationService.mark_all_read(USER_ID, mock_db)

        mock_db.commit.assert_called_once()




# save_fcm_token

class TestSaveFcmToken:

    async def test_saves_token(self, mock_db):
        mock_db.execute.return_value = MagicMock()

        await NotificationService.save_fcm_token(USER_ID, TOKEN, mock_db)

        mock_db.execute.assert_called_once()
        mock_db.commit.assert_called_once()

    async def test_commits_after_upsert(self, mock_db):
        mock_db.execute.return_value = MagicMock()

        await NotificationService.save_fcm_token(USER_ID, TOKEN, mock_db)

        mock_db.commit.assert_called_once()

    async def test_different_tokens_for_different_users(self, mock_db):
        mock_db.execute.return_value = MagicMock()

        await NotificationService.save_fcm_token(1, "token-1", mock_db)
        await NotificationService.save_fcm_token(2, "token-2", mock_db)

        assert mock_db.execute.call_count == 2
        assert mock_db.commit.call_count == 2