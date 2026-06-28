# test/unit/admin/test_announcement_service.py
from unittest.mock import MagicMock, AsyncMock, patch
from app.services.admin.announcement_service import get_announcements, create_announcement


GYM_ID = 5


def make_execute_result(scalars_all=None):
    result = MagicMock()
    result.scalars.return_value.all.return_value = scalars_all or []
    return result


# get_announcements

class TestGetAnnouncements:

    async def test_returns_empty_list_when_none(self, mock_db):
        mock_db.execute.return_value = make_execute_result(scalars_all=[])

        result = await get_announcements(GYM_ID, mock_db)

        assert result == []

    async def test_returns_announcements(self, mock_db, mock_announcement):
        mock_db.execute.return_value = make_execute_result(
            scalars_all=[mock_announcement]
        )

        result = await get_announcements(GYM_ID, mock_db)

        assert len(result) == 1
        assert result[0] == mock_announcement

    async def test_returns_multiple_announcements(self, mock_db, mock_announcement):
        second = MagicMock()
        second.announce_id = 2
        mock_db.execute.return_value = make_execute_result(
            scalars_all=[mock_announcement, second]
        )

        result = await get_announcements(GYM_ID, mock_db)

        assert len(result) == 2



# create_announcement

class TestCreateAnnouncement:

    async def test_adds_and_commits(self, mock_db, make_announcement_payload):
        payload = make_announcement_payload(reciever = "Client only")

        await create_announcement(GYM_ID, payload, mock_db)

        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
        mock_db.refresh.assert_called_once()


    async def test_strips_title_and_content(self, mock_db, make_announcement_payload):
        payload = make_announcement_payload(reciever = "Client only")
        added_announcement = None

        def capture_add(obj):
            nonlocal added_announcement
            added_announcement = obj

        mock_db.add.side_effect = capture_add

        await create_announcement(GYM_ID, payload, mock_db)

        assert added_announcement.title == "Test Title"
        assert added_announcement.content == "Test Content"


    async def test_notifies_clients_when_clients_only(self, mock_db, make_announcement_payload):
        payload = make_announcement_payload(reciever="Clients only")

        with patch("app.services.admin.announcement_service.notify_gym_clients", new_callable=AsyncMock) as mock_clients, \
             patch("app.services.admin.announcement_service.notify_gym_coaches", new_callable=AsyncMock) as mock_coaches:

            await create_announcement(GYM_ID, payload, mock_db)

            mock_clients.assert_called_once()
            mock_coaches.assert_not_called()

    async def test_notifies_coaches_when_coaches_only(self, mock_db, make_announcement_payload):
        payload = make_announcement_payload(reciever="Coaches only")

        with patch("app.services.admin.announcement_service.notify_gym_clients", new_callable=AsyncMock) as mock_clients, \
             patch("app.services.admin.announcement_service.notify_gym_coaches", new_callable=AsyncMock) as mock_coaches:

            await create_announcement(GYM_ID, payload, mock_db)

            mock_clients.assert_not_called()
            mock_coaches.assert_called_once()


    async def test_notifies_both_when_clients_and_coaches(self, mock_db, make_announcement_payload):
        payload = make_announcement_payload(reciever="Clients and Coaches")

        with patch("app.services.admin.announcement_service.notify_gym_clients", new_callable=AsyncMock) as mock_clients, \
             patch("app.services.admin.announcement_service.notify_gym_coaches", new_callable=AsyncMock) as mock_coaches:

            await create_announcement(GYM_ID, payload, mock_db)

            mock_clients.assert_called_once()
            mock_coaches.assert_called_once()


    async def test_notifies_nobody_when_unknown_reciever(self, mock_db, make_announcement_payload):
        payload = make_announcement_payload(reciever="Unknown")

        with patch("app.services.admin.announcement_service.notify_gym_clients", new_callable=AsyncMock) as mock_clients, \
             patch("app.services.admin.announcement_service.notify_gym_coaches", new_callable=AsyncMock) as mock_coaches:

            await create_announcement(GYM_ID, payload, mock_db)

            mock_clients.assert_not_called()
            mock_coaches.assert_not_called()


    async def test_passes_correct_gym_id_to_notify(self, mock_db, make_announcement_payload):
        payload = make_announcement_payload(reciever="Clients only")

        with patch("app.services.admin.announcement_service.notify_gym_clients", new_callable=AsyncMock) as mock_clients, \
             patch("app.services.admin.announcement_service.notify_gym_coaches", new_callable=AsyncMock):

            await create_announcement(GYM_ID, payload, mock_db)

            call_kwargs = mock_clients.call_args.kwargs
            assert call_kwargs["gym_id"] == GYM_ID


    async def test_returns_announcement(self, mock_db, make_announcement_payload, mock_announcement):
        payload = make_announcement_payload()
        mock_db.refresh = AsyncMock(side_effect=lambda obj: setattr(obj, "announce_id", 99))

        with patch("app.services.admin.announcement_service.notify_gym_clients", new_callable=AsyncMock), \
             patch("app.services.admin.announcement_service.notify_gym_coaches", new_callable=AsyncMock):

            result = await create_announcement(GYM_ID, payload, mock_db)

        assert result is not None