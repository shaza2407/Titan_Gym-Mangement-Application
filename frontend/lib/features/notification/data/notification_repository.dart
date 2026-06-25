import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/features/shared/api_constants.dart';
import '../domain/notification_model.dart';

class NotificationRepository {
  final int userId;
  final String token;

  const NotificationRepository({required this.userId, required this.token});

  Map<String, String> get _headers => {'Authorization': 'Bearer $token'};

  Future<List<NotificationModel>> fetchNotifications() async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/notifications/$userId'),
      headers: _headers,
    );
    if (res.statusCode != 200) return [];
    final List data = jsonDecode(res.body);
    return data
        .cast<Map<String, dynamic>>()
        .map(NotificationModel.fromMap)
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/notifications/$id/read'),
      headers: _headers,
    );
  }

  Future<void> markAllAsRead() async {
    await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/notifications/$userId/read-all'),
      headers: _headers,
    );
  }

  Future<void> saveFcmToken(String fcmToken) async {
    await http.post(
      Uri.parse(
          '${ApiConstants.baseUrl}/notifications/fcm-token?user_id=$userId&token=$fcmToken'),
      headers: _headers,
    );
  }
}