// lib/features/client/data/schedule_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/schedule_model.dart';
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';

class ScheduleRepository {
  final String baseUrl = ApiConstants.baseUrl;

  static const _statsCacheKey = 'client_schedule_stats';
  static const _myClassesCacheKey = 'client_schedule_my_classes';
  static const _browseCacheKey = 'client_schedule_browse';
  static const _weeklyCacheKey = 'client_schedule_weekly';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<ScheduleStatsModel> getStats(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/client/schedule/stats'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('Failed to load stats');
      await CacheService.save(_statsCacheKey, res.body);
      return ScheduleStatsModel.fromJson(jsonDecode(res.body));
    } catch (e) {
      final cached = await CacheService.load(_statsCacheKey);
      if (cached != null)
        return ScheduleStatsModel.fromJson(jsonDecode(cached));
      throw Exception('Unable to load your stats right now.');
    }
  }

  Future<List<ClassModel>> getMyClasses(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/client/schedule/my-classes'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('Failed to load my classes');
      await CacheService.save(_myClassesCacheKey, res.body);
      return (jsonDecode(res.body) as List)
          .map((e) => ClassModel.fromJson(e))
          .toList();
    } catch (e) {
      final cached = await CacheService.load(_myClassesCacheKey);
      if (cached != null) {
        return (jsonDecode(cached) as List)
            .map((e) => ClassModel.fromJson(e))
            .toList();
      }
      throw Exception('Unable to load your classes right now.');
    }
  }

  Future<List<ClassModel>> browseClasses(String token, {String? day}) async {
    final cacheKey = '$_browseCacheKey${day != null ? '_$day' : ''}';
    final url = day != null
        ? '$baseUrl/client/schedule/browse?day=$day'
        : '$baseUrl/client/schedule/browse';
    try {
      final res = await http
          .get(Uri.parse(url), headers: _headers(token))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('Failed to browse classes');
      await CacheService.save(cacheKey, res.body);
      return (jsonDecode(res.body) as List)
          .map((e) => ClassModel.fromJson(e))
          .toList();
    } catch (e) {
      final cached = await CacheService.load(cacheKey);
      if (cached != null) {
        return (jsonDecode(cached) as List)
            .map((e) => ClassModel.fromJson(e))
            .toList();
      }
      throw Exception('Unable to load classes right now.');
    }
  }

  Future<List<WeeklyDayModel>> getWeekly(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/client/schedule/weekly'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('Failed to load weekly');
      await CacheService.save(_weeklyCacheKey, res.body);
      return (jsonDecode(res.body) as List)
          .map((e) => WeeklyDayModel.fromJson(e))
          .toList();
    } catch (e) {
      final cached = await CacheService.load(_weeklyCacheKey);
      if (cached != null) {
        return (jsonDecode(cached) as List)
            .map((e) => WeeklyDayModel.fromJson(e))
            .toList();
      }
      throw Exception('Unable to load your weekly schedule right now.');
    }
  }

  // Writes: no cache fallback. Block with a clean, user-facing message instead of
  // letting a raw "Exception: SocketException..." or "Exception: Failed host lookup"
  // string reach the UI.
  Future<String> unenroll(String token, int sessionId, String classDate) async {
    try {
      final res = await http
          .delete(
            Uri.parse(
              '$baseUrl/client/schedule/unenroll/$sessionId?class_date=$classDate',
            ),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body)['message'];
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Unenroll failed');
    } catch (e) {
      if (e is Exception && e.toString().contains('detail')) rethrow;
      throw Exception(
        'Could not unenroll — check your connection and try again.',
      );
    }
  }

  Future<String> enroll(String token, int sessionId, String classDate) async {
    try {
      final res = await http
          .post(
            Uri.parse(
              '$baseUrl/client/schedule/enroll/$sessionId?class_date=$classDate',
            ),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body)['message'];
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Enroll failed');
    } catch (e) {
      if (e is Exception && e.toString().contains('detail')) rethrow;
      throw Exception(
        'Could not enroll — check your connection and try again.',
      );
    }
  }
}
