import 'dart:convert';
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import 'package:http/http.dart' as http;
import '../domain/coach_dashboard_model.dart';

class CoachDashboardRepository {
  final String baseUrl = ApiConstants.baseUrl;

  static const _statsCacheKey = 'coach_dashboard_stats';
  static const _upcomingCacheKey = 'coach_dashboard_upcoming';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<CoachDashboardStatsModel> getStats(String token) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/coach/dashboard'), headers: _headers(token))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('Failed to load dashboard stats');
      }
      await CacheService.save(_statsCacheKey, res.body);
      return CoachDashboardStatsModel.fromJson(jsonDecode(res.body));
    } catch (e) {
      final cached = await CacheService.load(_statsCacheKey);
      if (cached != null) {
        return CoachDashboardStatsModel.fromJson(jsonDecode(cached));
      }
      throw Exception(
        'Unable to load your dashboard stats. Check your connection.',
      );
    }
  }

  Future<List<CoachUpcomingClassModel>> getUpcoming(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/coach/dashboard/upcoming'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('Failed to load upcoming classes');
      }
      await CacheService.save(_upcomingCacheKey, res.body);
      return (jsonDecode(res.body) as List)
          .map((e) => CoachUpcomingClassModel.fromJson(e))
          .toList();
    } catch (e) {
      final cached = await CacheService.load(_upcomingCacheKey);
      if (cached != null) {
        return (jsonDecode(cached) as List)
            .map((e) => CoachUpcomingClassModel.fromJson(e))
            .toList();
      }
      throw Exception(
        'Unable to load upcoming classes. Check your connection.',
      );
    }
  }
}
