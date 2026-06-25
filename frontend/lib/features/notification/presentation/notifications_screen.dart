import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/shared/invitation_accept_screen.dart';
import './controller/notification_controller.dart';
import '../domain/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  final int userId;
  final String token;
  final VoidCallback? onDataChanged;

  const NotificationsScreen({
    super.key,
    required this.userId,
    required this.token,
    this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          NotificationController(userId: userId, token: token)..load(),
      child: _NotificationsView(onDataChanged: onDataChanged),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  final VoidCallback? onDataChanged;

  const _NotificationsView({this.onDataChanged});

  static const _accent = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () async {
            await controller.load();
            if (context.mounted) Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(
              controller.unreadCount > 0
                  ? '${controller.unreadCount} unread'
                  : 'All caught up',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (controller.unreadCount > 0)
            TextButton(
              onPressed: controller.markAllAsRead,
              child: const Text('Mark all read',
                  style: TextStyle(color: _accent, fontSize: 12)),
            ),
        ],
      ),
      body: controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _accent))
          : controller.notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No notifications yet',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 15)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.notifications.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final n = controller.notifications[index];
                      return _NotificationTile(
                        notification: n,
                        controller: controller,
                        onDataChanged: onDataChanged,
                      );
                    },
                  ),
                ),
    );
  }
}

// ── Notification Tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final NotificationController controller;
  final VoidCallback? onDataChanged;

  const _NotificationTile({
    required this.notification,
    required this.controller,
    this.onDataChanged,
  });

  static const _accent = Color(0xFF6C63FF);

  Future<void> _onTap(BuildContext context) async {
    if (!notification.isRead) {
      await controller.markAsRead(notification.id);
    }

    final type = notification.type;
    if (type == 'gym_invite_client' || type == 'gym_invite_coach') {
      final gymId = int.tryParse(
          notification.data['gym_id']?.toString() ?? '');
      final inviteToken =
          notification.data['invite_token']?.toString() ?? '';
      final gymName =
          notification.data['gym_name']?.toString() ?? 'Gym';

      if (gymId != null && inviteToken.isNotEmpty && context.mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvitationScreen(
              gymId:       gymId,
              inviteToken: inviteToken,
              gymName:     gymName,
              authToken:   controller.token, // expose token via getter
              role: type == 'gym_invite_coach' ? 'coach' : 'client',
            ),
          ),
        );

        await controller.load();
        if (result == true) onDataChanged?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : _accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead
                ? Colors.transparent
                : _accent.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                controller.iconForType(notification.type),
                color: _accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight:
                          isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(notification.body,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(controller.timeAgo(notification.createdAt),
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),

            // Unread dot
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}