import 'package:flutter/material.dart';
import 'notification_badge_repository.dart';


class NotificationBadgeController extends ChangeNotifier {
  final _repo = NotificationBadgeRepository();

  bool hasUnread = false;
  bool _disposed = false;

  Future<void> load(String token, int userId) async {
    try {
      final result = await _repo.fetchBadge(token, userId);
      hasUnread = result.hasUnread;
    } catch (_) {
      hasUnread = false;
    }
    if (!_disposed) notifyListeners();
  }

  void clear() {
    hasUnread = false;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}