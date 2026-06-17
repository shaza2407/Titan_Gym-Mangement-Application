import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/features/shared/api_constants.dart';

class NotificationRepository {
  

  static Future<List<Map<String, dynamic>>> fetchNotifications(
      String email, String token) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/notifications?email=$email'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (res.statusCode != 200) return [];
    final List data = jsonDecode(res.body);
    return data.cast<Map<String, dynamic>>();
  }

  static Future<void> markAsRead(String id, String token) async {
    await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/notifications/$id/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}