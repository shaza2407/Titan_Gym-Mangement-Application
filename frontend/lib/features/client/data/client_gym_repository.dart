import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import '../domain/gym_model.dart';

class ClientGymRepository {
  final String baseUrl = ApiConstants.baseUrl;

  static const _gymCacheKey = 'client_gym_info';
  static const _announcementsCacheKey = 'client_gym_announcements';
  static const _scheduleCacheKey = 'client_gym_weekly_schedule';

  Future<GymInfoModel> getMyGym(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/client/gym'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) throw Exception('Failed to load gym info');

      await CacheService.save(_gymCacheKey, res.body);
      return GymInfoModel.fromJson(jsonDecode(res.body));
    } catch (e) {
      final cached = await CacheService.load(_gymCacheKey);
      if (cached != null) {
        return GymInfoModel.fromJson(jsonDecode(cached));
      }
      throw Exception(
        'Unable to load gym info. Check your connection and try again.',
      );
    }
  }

  Future<List<AnnouncementModel>> getAnnouncements(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/client/gym/announcements'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw Exception('Failed to load announcements');
      }

      await CacheService.save(_announcementsCacheKey, res.body);
      final List data = jsonDecode(res.body);
      return data.map((e) => AnnouncementModel.fromJson(e)).toList();
    } catch (e) {
      final cached = await CacheService.load(_announcementsCacheKey);
      if (cached != null) {
        final List data = jsonDecode(cached);
        return data.map((e) => AnnouncementModel.fromJson(e)).toList();
      }
      throw Exception(
        'Unable to load announcements. Check your connection and try again.',
      );
    }
  }

  Future<Map<String, List<GymClassModel>>> getWeeklySchedule(
    String token,
  ) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/client/gym/weekly-schedule'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) throw Exception('Failed to load schedule');

      await CacheService.save(_scheduleCacheKey, res.body);
      return _parseSchedule(res.body);
    } catch (e) {
      final cached = await CacheService.load(_scheduleCacheKey);
      if (cached != null) {
        return _parseSchedule(cached);
      }
      throw Exception(
        'Unable to load schedule. Check your connection and try again.',
      );
    }
  }

  Map<String, List<GymClassModel>> _parseSchedule(String body) {
    final Map<String, dynamic> data = jsonDecode(body);
    return data.map((day, classes) {
      final list = (classes as List)
          .map((c) => GymClassModel.fromJson(c))
          .toList();
      return MapEntry(day, list);
    });
  }
}
