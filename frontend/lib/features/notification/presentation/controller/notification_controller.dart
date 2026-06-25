import 'package:flutter/material.dart';
import '../../data/notification_repository.dart';
import '../../domain/notification_model.dart';

class NotificationController extends ChangeNotifier {
  final NotificationRepository _repo;

  NotificationController({required int userId, required String token})
      : _repo = NotificationRepository(userId: userId, token: token);

  String get token => _repo.token;
  // ── State ─────────────────────────────────────────────────────────────────
  List<NotificationModel> notifications = [];
  bool isLoading = true;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      notifications = await _repo.fetchNotifications();
    } catch (_) {
      notifications = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Mark as Read ──────────────────────────────────────────────────────────
  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead();
    notifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  // ── Formatters ────────────────────────────────────────────────────────────
  String timeAgo(String createdAt) {
    final date = DateTime.parse(createdAt).toLocal();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData iconForType(String type) {
    switch (type) {
      case 'gym_invite_client':   return Icons.fitness_center;
      case 'gym_invite_coach':    return Icons.sports_gymnastics;
      case 'coach_class_request': return Icons.calendar_today;
      default:                    return Icons.notifications;
    }
  }
}