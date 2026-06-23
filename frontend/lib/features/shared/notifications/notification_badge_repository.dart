import 'dart:convert';
import 'package:http/http.dart' as http;
import 'notification_model.dart';
import '../api_constants.dart';

class NotificationBadgeRepository {
  Future<NotificationBadgeModel> fetchBadge(String token, int userId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/notifications/$userId/unread-count'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return NotificationBadgeModel(hasUnread: data['has_unread'] == true);
    }
    return const NotificationBadgeModel(hasUnread: false);
  }
}
