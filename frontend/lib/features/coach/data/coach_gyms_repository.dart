import 'dart:convert';
import 'package:frontend/features/admin/domain/schedule_model.dart';
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import 'package:http/http.dart' as http;
import '../domain/coach_gyms_model.dart';

class CoachGymsRepository {
  final String baseUrl = ApiConstants.baseUrl;

  static const _gymsCacheKey = 'coach_my_gyms';
  static const _announcementsCacheKey = 'coach_gym_announcements';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<CoachGymModel>> getCoachGyms(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/coach/gyms/my-gyms'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('Failed to load gyms');
      await CacheService.save(_gymsCacheKey, res.body);
      final List data = jsonDecode(res.body);
      return data.map((e) => CoachGymModel.fromJson(e)).toList();
    } catch (e) {
      final cached = await CacheService.load(_gymsCacheKey);
      if (cached != null) {
        final List data = jsonDecode(cached);
        return data.map((e) => CoachGymModel.fromJson(e)).toList();
      }
      throw Exception('Unable to load your gyms. Check your connection.');
    }
  }

  Future<List<CoachAnnouncementModel>> getGymAnnouncements(
    String token, {
    int? gymId,
  }) async {
    final cacheKey = gymId != null
        ? '${_announcementsCacheKey}_$gymId'
        : _announcementsCacheKey;
    final query = gymId != null ? '?gym_id=$gymId' : '';
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/coach/gyms/my-announcements$query'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('Failed to load announcements');
      }
      await CacheService.save(cacheKey, res.body);
      final List data = jsonDecode(res.body);
      return data.map((e) => CoachAnnouncementModel.fromJson(e)).toList();
    } catch (e) {
      final cached = await CacheService.load(cacheKey);
      if (cached != null) {
        final List data = jsonDecode(cached);
        return data.map((e) => CoachAnnouncementModel.fromJson(e)).toList();
      }
      throw Exception('Unable to load announcements. Check your connection.');
    }
  }
}

class GymScheduleRepository {
  final String baseUrl = ApiConstants.baseUrl;

  static const _classesCacheKeyPrefix = 'coach_gym_classes';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<ClassSessionModel>> getClasses(
    String token,
    int gymId, {
    String? fromDate,
    String? weekStart,
    String? weekEnd,
  }) async {
    final params = <String>[];
    if (fromDate != null) params.add('from_date=$fromDate');
    if (weekStart != null) params.add('week_start=$weekStart');
    if (weekEnd != null) params.add('week_end=$weekEnd');
    final query = params.isNotEmpty ? '&${params.join('&')}' : '';
    final cacheKey =
        '${_classesCacheKeyPrefix}_${gymId}_${weekStart ?? fromDate ?? 'default'}';

    try {
      final res = await http
          .get(
            Uri.parse(
              '${ApiConstants.baseUrl}/coach/gyms/classes?gym_id=$gymId$query',
            ),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('Failed to load classes');
      await CacheService.save(cacheKey, res.body);
      final data = jsonDecode(res.body) as List;
      return data.map((e) => ClassSessionModel.fromJson(e)).toList();
    } catch (e) {
      final cached = await CacheService.load(cacheKey);
      if (cached != null) {
        final data = jsonDecode(cached) as List;
        return data.map((e) => ClassSessionModel.fromJson(e)).toList();
      }
      throw Exception(
        'Unable to load this gym\'s schedule. Check your connection.',
      );
    }
  }
}
