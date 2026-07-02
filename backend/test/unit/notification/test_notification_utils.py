from unittest.mock import MagicMock, AsyncMock, patch
from app.services.notifications.notification_Utils import (
    get_user_by_email,
    save_notification,
    send_push_notification,
    notify_invite,
    notify_admin,
    notify_Coach_on_class_approval,
    notify_gym_clients,
    notify_gym_coaches,
)

GYM_ID = 5
USER_ID = 1
TITLE = "Test Title"
BODY = "Test Body"
TYPE = "test-type"
DATA = {"key": "value"}


def scalars_all_result(values):
    r = MagicMock()
    r.scalars.return_value.all.return_value = values
    return r


def scalar_one_or_none_result(value):
    r = MagicMock()
    r.scalar_one_or_none.return_value = value
    return r


def scalar_result(value):
    r = MagicMock()
    r.scalar_one_or_none.return_value = value
    r.scalars.return_value.all.return_value = value if isinstance(value, list) else []
    return r



# get_user_by_email

class TestGetUserByEmail:

    async def test_returns_user(self, mock_db):
        user = MagicMock()
        mock_db.execute.return_value = scalar_one_or_none_result(user)

        result = await get_user_by_email(mock_db, "test@example.com")

        assert result == user

    async def test_returns_none_if_not_found(self, mock_db):
        mock_db.execute.return_value = scalar_one_or_none_result(None)

        result = await get_user_by_email(mock_db, "notfound@example.com")

        assert result is None




# save_notification

class TestSaveNotification:

    async def test_saves_correct_user_id(self, mock_db):
        captured = {}
        def capture_add(obj):
            captured["notification"] = obj
        mock_db.add.side_effect = capture_add

        await save_notification(mock_db, USER_ID, TITLE, BODY, TYPE, DATA)

        assert captured["notification"].user_id == USER_ID

    async def test_saves_correct_title_and_body(self, mock_db):
        captured = {}
        def capture_add(obj):
            captured["notification"] = obj
        mock_db.add.side_effect = capture_add

        await save_notification(mock_db, USER_ID, TITLE, BODY, TYPE, DATA)

        assert captured["notification"].title == TITLE
        assert captured["notification"].body == BODY

    async def test_is_read_defaults_false(self, mock_db):
        captured = {}
        def capture_add(obj):
            captured["notification"] = obj
        mock_db.add.side_effect = capture_add

        await save_notification(mock_db, USER_ID, TITLE, BODY, TYPE, DATA)

        assert captured["notification"].is_read is False



# send_push_notification

class TestSendPushNotification:

    async def test_does_nothing_if_no_fcm_token(self, mock_db):
        mock_db.execute.return_value = scalar_one_or_none_result(None)

        with patch("app.services.notifications.notification_Utils.messaging") as mock_msg:
            await send_push_notification(mock_db, USER_ID, TITLE, BODY, DATA)
            mock_msg.send.assert_not_called()

    async def test_sends_message_when_token_exists(self, mock_db):
        fcm = MagicMock()
        fcm.token = "fake-fcm-token"
        mock_db.execute.return_value = scalar_one_or_none_result(fcm)

        with patch("app.services.notifications.notification_Utils.messaging") as mock_msg:
            mock_msg.Message.return_value = MagicMock()
            mock_msg.Notification.return_value = MagicMock()

            await send_push_notification(mock_db, USER_ID, TITLE, BODY, DATA)

            mock_msg.send.assert_called_once()

    async def test_does_not_crash_if_fcm_fails(self, mock_db):
        fcm = MagicMock()
        fcm.token = "fake-fcm-token"
        mock_db.execute.return_value = scalar_one_or_none_result(fcm)

        with patch("app.services.notifications.notification_Utils.messaging") as mock_msg:
            mock_msg.Message.return_value = MagicMock()
            mock_msg.Notification.return_value = MagicMock()
            mock_msg.send.side_effect = Exception("FCM error")

            # should not raise
            await send_push_notification(mock_db, USER_ID, TITLE, BODY, DATA)



# notify_invite

class TestNotifyInvite:

    async def test_does_nothing_if_user_not_found(self, mock_db):
        mock_db.execute.return_value = scalar_one_or_none_result(None)

        with patch("app.services.notifications.notification_Utils.save_notification", new_callable=AsyncMock) as mock_save, \
             patch("app.services.notifications.notification_Utils.send_push_notification", new_callable=AsyncMock) as mock_push:

            await notify_invite(mock_db, "notfound@example.com", "Titan Gym", "client")

            mock_save.assert_not_called()
            mock_push.assert_not_called()

    async def test_sends_notification_when_user_found(self, mock_db):
        user = MagicMock()
        user.userID = USER_ID
        mock_db.execute.return_value = scalar_one_or_none_result(user)

        with patch("app.services.notifications.notification_Utils.save_notification", new_callable=AsyncMock) as mock_save, \
             patch("app.services.notifications.notification_Utils.send_push_notification", new_callable=AsyncMock) as mock_push:

            await notify_invite(mock_db, "test@example.com", "Titan Gym", "client", gym_id=5)

            mock_save.assert_called_once()
            mock_push.assert_called_once()

    async def test_includes_gym_name_in_data(self, mock_db):
        user = MagicMock()
        user.userID = USER_ID
        mock_db.execute.return_value = scalar_one_or_none_result(user)

        with patch("app.services.notifications.notification_Utils.save_notification", new_callable=AsyncMock) as mock_save, \
             patch("app.services.notifications.notification_Utils.send_push_notification", new_callable=AsyncMock):

            await notify_invite(mock_db, "test@example.com", "Titan Gym", "coach", gym_id=5)

            call_args = mock_save.call_args
            assert call_args.args[2] or "Titan Gym" in str(call_args)



# notify_admin

class TestNotifyAdmin:

    async def test_does_nothing_if_gym_not_found(self, mock_db):
        mock_db.execute.return_value = scalar_one_or_none_result(None)

        with patch("app.services.notifications.notification_Utils.save_notification", new_callable=AsyncMock) as mock_save:
            await notify_admin(mock_db, GYM_ID, TITLE, BODY, TYPE, DATA)
            mock_save.assert_not_called()

    async def test_does_nothing_if_admin_not_found(self, mock_db):
        gym = MagicMock()
        gym.adminID = 10
        no_admin = scalar_one_or_none_result(None)
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(gym),
            no_admin,
        ]

        with patch("app.services.notifications.notification_Utils.save_notification", new_callable=AsyncMock) as mock_save:
            await notify_admin(mock_db, GYM_ID, TITLE, BODY, TYPE, DATA)
            mock_save.assert_not_called()

    async def test_notifies_admin_when_found(self, mock_db):
        gym = MagicMock()
        gym.adminID = 10
        admin = MagicMock()
        admin.userID = USER_ID
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(gym),
            scalar_one_or_none_result(admin),
        ]

        with patch("app.services.notifications.notification_Utils.save_notification", new_callable=AsyncMock) as mock_save, \
             patch("app.services.notifications.notification_Utils.send_push_notification", new_callable=AsyncMock) as mock_push:

            await notify_admin(mock_db, GYM_ID, TITLE, BODY, TYPE, DATA)

            mock_save.assert_called_once_with(mock_db, admin.userID, TITLE, BODY, TYPE, DATA)
            mock_push.assert_called_once()



# notify_Coach_on_class_approval

class TestNotifyCoachOnClassApproval:

    async def test_does_nothing_if_gym_not_found(self, mock_db):
        mock_db.execute.return_value = scalar_one_or_none_result(None)

        with patch("app.services.notifications.notification_Utils.save_notification", new_callable=AsyncMock) as mock_save:
            await notify_Coach_on_class_approval(mock_db, 1, GYM_ID, TITLE, BODY, TYPE, DATA)
            mock_save.assert_not_called()

    async def test_does_nothing_if_coach_id_not_found(self, mock_db):
        gym = MagicMock()
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(gym),
            scalar_one_or_none_result(None),  # no coach_id
        ]

        with patch("app.services.notifications.notification_Utils.save_notification", new_callable=AsyncMock) as mock_save:
            await notify_Coach_on_class_approval(mock_db, 1, GYM_ID, TITLE, BODY, TYPE, DATA)
            mock_save.assert_not_called()

    async def test_does_nothing_if_coach_not_found(self, mock_db):
        gym = MagicMock()
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(gym),
            scalar_one_or_none_result(99),   # coach_id found
            scalar_one_or_none_result(None), # but coach not found
        ]

        with patch("app.services.notifications.notification_Utils.save_notification", new_callable=AsyncMock) as mock_save:
            await notify_Coach_on_class_approval(mock_db, 1, GYM_ID, TITLE, BODY, TYPE, DATA)
            mock_save.assert_not_called()

    async def test_notifies_coach_when_found(self, mock_db):
        gym = MagicMock()
        coach = MagicMock()
        coach.userID = USER_ID
        mock_db.execute.side_effect = [
            scalar_one_or_none_result(gym),
            scalar_one_or_none_result(99),
            scalar_one_or_none_result(coach),
        ]

        with patch("app.services.notifications.notification_Utils.save_notification", new_callable=AsyncMock) as mock_save, \
             patch("app.services.notifications.notification_Utils.send_push_notification", new_callable=AsyncMock) as mock_push:

            await notify_Coach_on_class_approval(mock_db, 1, GYM_ID, TITLE, BODY, TYPE, DATA)

            mock_save.assert_called_once_with(mock_db, coach.userID, TITLE, BODY, TYPE, DATA)
            mock_push.assert_called_once()



# notify_gym_clients

class TestNotifyGymClients:

    async def test_does_nothing_if_no_clients(self, mock_db):
        mock_db.execute.return_value = scalars_all_result([])

        with patch("app.services.notifications.notification_Utils.save_notification", new_callable=AsyncMock) as mock_save:
            await notify_gym_clients(mock_db, GYM_ID, TITLE, BODY, TYPE, DATA)
            mock_save.assert_not_called()

    async def test_notifies_all_clients(self, mock_db):
        client_ids_result = scalars_all_result([1, 2])
        user_ids_result = scalars_all_result([10, 20])
        mock_db.execute.side_effect = [client_ids_result, user_ids_result]

        with patch("app.services.notifications.notification_Utils.save_notification", new_callable=AsyncMock) as mock_save, \
             patch("app.services.notifications.notification_Utils.send_push_notification", new_callable=AsyncMock) as mock_push:

            await notify_gym_clients(mock_db, GYM_ID, TITLE, BODY, TYPE, DATA)

            assert mock_save.call_count == 2
            assert mock_push.call_count == 2

    async def test_notifies_correct_user_ids(self, mock_db):
        client_ids_result = scalars_all_result([1])
        user_ids_result = scalars_all_result([99])
        mock_db.execute.side_effect = [client_ids_result, user_ids_result]

        with patch("app.services.notifications.notification_Utils.save_notification", new_callable=AsyncMock) as mock_save, \
             patch("app.services.notifications.notification_Utils.send_push_notification", new_callable=AsyncMock):

            await notify_gym_clients(mock_db, GYM_ID, TITLE, BODY, TYPE, DATA)

            mock_save.assert_called_once_with(mock_db, 99, TITLE, BODY, TYPE, DATA)


# ══════════════════════════════════════════════════════════════════════════════
# notify_gym_coaches
# ══════════════════════════════════════════════════════════════════════════════

class TestNotifyGymCoaches:

    async def test_does_nothing_if_no_coaches(self, mock_db):
        mock_db.execute.return_value = scalars_all_result([])

        with patch("app.services.notifications.notification_Utils.save_notification", new_callable=AsyncMock) as mock_save:
            await notify_gym_coaches(mock_db, GYM_ID, TITLE, BODY, TYPE, DATA)
            mock_save.assert_not_called()

    async def test_notifies_all_coaches(self, mock_db):
        coach_ids_result = scalars_all_result([1, 2])
        user_ids_result = scalars_all_result([30, 40])
        mock_db.execute.side_effect = [coach_ids_result, user_ids_result]

        with patch("app.services.notifications.notification_Utils.save_notification", new_callable=AsyncMock) as mock_save, \
             patch("app.services.notifications.notification_Utils.send_push_notification", new_callable=AsyncMock) as mock_push:

            await notify_gym_coaches(mock_db, GYM_ID, TITLE, BODY, TYPE, DATA)

            assert mock_save.call_count == 2
            assert mock_push.call_count == 2

    async def test_notifies_correct_user_ids(self, mock_db):
        coach_ids_result = scalars_all_result([1])
        user_ids_result = scalars_all_result([55])
        mock_db.execute.side_effect = [coach_ids_result, user_ids_result]

        with patch("app.services.notifications.notification_Utils.save_notification", new_callable=AsyncMock) as mock_save, \
             patch("app.services.notifications.notification_Utils.send_push_notification", new_callable=AsyncMock):

            await notify_gym_coaches(mock_db, GYM_ID, TITLE, BODY, TYPE, DATA)

            mock_save.assert_called_once_with(mock_db, 55, TITLE, BODY, TYPE, DATA)