import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/features/shared/api_constants.dart';
import '../../shared/cache_service.dart';
import '../../shared/connectivity_helper.dart';
import '../domain/notification_model.dart';

class NotificationRepository {
  final int userId;
  final String token;

  NotificationRepository({required this.userId, required this.token});

  String get _cacheKey => 'cache_notifications_$userId';

  Map<String, String> get _headers => {'Authorization': 'Bearer $token'};

  Future<List<NotificationModel>> fetchNotifications() async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) return _loadFromCache();

    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications/$userId'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        await CacheService.save(_cacheKey, res.body);
        final List data = jsonDecode(res.body);
        return data.cast<Map<String, dynamic>>().map(NotificationModel.fromMap).toList();
      }
      return _loadFromCache();
    } catch (e) {
      return _loadFromCache();
    }
  }

  Future<List<NotificationModel>> _loadFromCache() async {
    try {
      final cached = await CacheService.load(_cacheKey);
      if (cached == null) return [];
      final List data = jsonDecode(cached);
      return data.cast<Map<String, dynamic>>().map(NotificationModel.fromMap).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/notifications/$id/read'),
        headers: _headers,
      );
      await _updateCachedNotification(id, isRead: true);
    } catch (e) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/notifications/$userId/read-all'),
        headers: _headers,
      );
      await _markAllCachedAsRead();
    } catch (e) {}
  }

  Future<void> saveFcmToken(String fcmToken) async {
    await http.post(
      Uri.parse(
          '${ApiConstants.baseUrl}/notifications/fcm-token?user_id=$userId&token=$fcmToken'),
      headers: _headers,
    );
  }

  // ─── Cache Sync Helpers ───────────────────────────────────────────────────

  Future<void> _updateCachedNotification(String id, {required bool isRead}) async {
    try {
      final cached = await CacheService.load(_cacheKey);
      if (cached == null) return;
      final List data = jsonDecode(cached);
      final updated = data.map((e) {
        if (e['id'].toString() == id) return {...e, 'is_read': isRead};
        return e;
      }).toList();
      await CacheService.save(_cacheKey, jsonEncode(updated));
    } catch (e) {}
  }

  Future<void> _markAllCachedAsRead() async {
    try {
      final cached = await CacheService.load(_cacheKey);
      if (cached == null) return;
      final List data = jsonDecode(cached);
      final updated = data.map((e) => {...e, 'is_read': true}).toList();
      await CacheService.save(_cacheKey, jsonEncode(updated));
    } catch (e) {}
  }
}