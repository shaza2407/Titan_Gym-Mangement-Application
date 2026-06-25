import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/announcement_model.dart';
import '../../shared/api_constants.dart';

class AnnouncementRepository {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<Announcement>> getAnnouncements({
    required String token,
    required int gymId,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/announcements'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .asMap()
          .entries
          .map((e) => Announcement.fromJson(e.value, e.key))
          .toList();
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  Future<void> createAnnouncement({
    required String token,
    required int gymId,
    required CreateAnnouncementRequest request,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/announcements'),
      headers: _headers(token),
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        jsonDecode(response.body)['detail'] ?? 'Failed to create announcement',
      );
    }
  }
}