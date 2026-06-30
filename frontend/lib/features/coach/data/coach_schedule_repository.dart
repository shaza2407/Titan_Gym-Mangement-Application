import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import '../domain/coach_schedule_model.dart';

class CoachScheduleRepository {
  final String baseUrl = ApiConstants.baseUrl;

  static const _statsCacheKey = 'coach_schedule_stats';
  static const _weeklyCacheKey = 'coach_schedule_weekly';
  static const _myClassesCacheKey = 'coach_schedule_my_classes';
  static const _requestsCacheKey = 'coach_schedule_requests';
  static const _gymsCacheKey = 'coach_schedule_gyms';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<CoachScheduleStatsModel> getStats(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/coach/schedule/stats'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('Failed to load schedule stats');
      }
      await CacheService.save(_statsCacheKey, res.body);
      return CoachScheduleStatsModel.fromJson(jsonDecode(res.body));
    } catch (e) {
      final cached = await CacheService.load(_statsCacheKey);
      if (cached != null) {
        return CoachScheduleStatsModel.fromJson(jsonDecode(cached));
      }
      throw Exception('Unable to load schedule stats. Check your connection.');
    }
  }

  Future<List<CoachWeeklyDayModel>> getWeekly(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/coach/schedule/weekly'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('Failed to load weekly schedule');
      }
      await CacheService.save(_weeklyCacheKey, res.body);
      return (jsonDecode(res.body) as List)
          .map((e) => CoachWeeklyDayModel.fromJson(e))
          .toList();
    } catch (e) {
      final cached = await CacheService.load(_weeklyCacheKey);
      if (cached != null) {
        return (jsonDecode(cached) as List)
            .map((e) => CoachWeeklyDayModel.fromJson(e))
            .toList();
      }
      throw Exception(
        'Unable to load your weekly schedule. Check your connection.',
      );
    }
  }

  Future<List<CoachClassModel>> getMyClasses(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/coach/schedule/my-classes'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('Failed to load my classes');
      await CacheService.save(_myClassesCacheKey, res.body);
      return (jsonDecode(res.body) as List)
          .map((e) => CoachClassModel.fromJson(e))
          .toList();
    } catch (e) {
      final cached = await CacheService.load(_myClassesCacheKey);
      if (cached != null) {
        return (jsonDecode(cached) as List)
            .map((e) => CoachClassModel.fromJson(e))
            .toList();
      }
      throw Exception('Unable to load your classes. Check your connection.');
    }
  }

  Future<List<CoachClassRequestModel>> getRequests(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/coach/schedule/requests'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('Failed to load requests');
      await CacheService.save(_requestsCacheKey, res.body);
      return (jsonDecode(res.body) as List)
          .map((e) => CoachClassRequestModel.fromJson(e))
          .toList();
    } catch (e) {
      final cached = await CacheService.load(_requestsCacheKey);
      if (cached != null) {
        return (jsonDecode(cached) as List)
            .map((e) => CoachClassRequestModel.fromJson(e))
            .toList();
      }
      throw Exception('Unable to load your requests. Check your connection.');
    }
  }

  Future<List<CoachGymLookupModel>> getGyms(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/coach/schedule/gyms'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('Failed to load gyms');
      await CacheService.save(_gymsCacheKey, res.body);
      return (jsonDecode(res.body) as List)
          .map((e) => CoachGymLookupModel.fromJson(e))
          .toList();
    } catch (e) {
      final cached = await CacheService.load(_gymsCacheKey);
      if (cached != null) {
        return (jsonDecode(cached) as List)
            .map((e) => CoachGymLookupModel.fromJson(e))
            .toList();
      }
      throw Exception(
        'Unable to load gyms for the request form. Check your connection.',
      );
    }
  }

  // ── Writes: no cache, no fallback, clean messages ──────────────────────

  Future<String> createRequest(String token, Map<String, dynamic> data) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/coach/schedule/requests'),
            headers: _headers(token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 201) return jsonDecode(res.body)['message'];
      throw Exception(
        jsonDecode(res.body)['detail'] ?? 'Failed to create request',
      );
    } catch (e) {
      if (e is Exception && e.toString().contains('detail')) rethrow;
      throw Exception(
        'Could not submit request — check your connection and try again.',
      );
    }
  }

  Future<void> removeClass(String token, int classId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/coach/schedule/my-classes/$classId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) throw Exception('Failed to remove class');
    } catch (e) {
      throw Exception(
        'Could not remove this class — check your connection and try again.',
      );
    }
  }

  Future<void> removeRequest(String token, int requestId) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$baseUrl/coach/schedule/requests/$requestId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception(
          jsonDecode(res.body)['detail'] ?? 'Failed to cancel request',
        );
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('detail')) rethrow;
      throw Exception(
        'Could not cancel this request — check your connection and try again.',
      );
    }
  }
}
