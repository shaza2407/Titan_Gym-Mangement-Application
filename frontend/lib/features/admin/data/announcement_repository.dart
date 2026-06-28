import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/announcement_model.dart';
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import '../../shared/connectivity_helper.dart';

class AnnouncementRepository {
  static String _cacheKey(int gymId) => 'cache_announcements_$gymId';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<Announcement>> getAnnouncements({
    required String token,
    required int gymId,
  }) async {
    final cacheKey = _cacheKey(gymId);
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(cacheKey);
      if (cached != null) {
        final List data = jsonDecode(cached);
        return data
            .asMap()
            .entries
            .map((e) => Announcement.fromJson(e.value, e.key))
            .toList();
      }
      throw Exception('You are offline and no cached announcements available.');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/announcements'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      await CacheService.save(cacheKey, response.body);
      final List data = jsonDecode(response.body);
      return data
          .asMap()
          .entries
          .map((e) => Announcement.fromJson(e.value, e.key))
          .toList();
    }

    // Server error — fall back to cache
    final cached = await CacheService.load(cacheKey);
    if (cached != null) {
      final List data = jsonDecode(cached);
      return data
          .asMap()
          .entries
          .map((e) => Announcement.fromJson(e.value, e.key))
          .toList();
    }

    throw Exception(jsonDecode(response.body)['detail']);
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

    await CacheService.clear(_cacheKey(gymId)); // invalidate so list refreshes
  }
}