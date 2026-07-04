import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import '../../shared/connectivity_helper.dart';

class GymStatsRepository {
  // Cache keys
  static const _totalMembersKey = 'cache_gym_stats_total_members';
  static String _gymStatsKey(int gymId) => 'cache_gym_stats_$gymId';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Total Members

  Future<int> getTotalMembers({required String token}) async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_totalMembersKey);
      if (cached != null) return int.tryParse(cached) ?? 0;
      return 0;
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/gyms/total-members'),
      headers: _headers(token),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final total = (jsonDecode(response.body)['total'] as int?) ?? 0;
      await CacheService.save(_totalMembersKey, total.toString());
      return total;
    }

    final cached = await CacheService.load(_totalMembersKey);
    return int.tryParse(cached ?? '') ?? 0;
  }

  // Per-Gym Stats (batched into one cache entry per gym)

  /// Loads member/coach/class counts for a gym, using a single cache entry.
  /// Returns a map with keys: 'members', 'coaches', 'classes'
  Future<Map<String, int>> getGymStats({
    required String token,
    required int gymId,
  }) async {
    final cacheKey = _gymStatsKey(gymId);
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      return _loadGymStatsFromCache(cacheKey);
    }

    // Fetch all three in parallel
    final results = await Future.wait([
      _fetchCount(
        token: token,
        url: '${ApiConstants.baseUrl}/gyms/$gymId/member-count',
        field: 'count',
      ),
      _fetchCount(
        token: token,
        url: '${ApiConstants.baseUrl}/gyms/$gymId/coach-count',
        field: 'count',
      ),
      _fetchCount(
        token: token,
        url: '${ApiConstants.baseUrl}/gyms/$gymId/class-count',
        field: 'count',
      ),
    ]);

    final stats = {
      'members': results[0],
      'coaches': results[1],
      'classes': results[2],
    };

    await CacheService.save(cacheKey, jsonEncode(stats));
    return stats;
  }


  Future<int> getGymMemberCount({
    required String token,
    required int gymId,
  }) async {
    final stats = await getGymStats(token: token, gymId: gymId);
    return stats['members'] ?? 0;
  }

  Future<int> getGymCoachCount({
    required String token,
    required int gymId,
  }) async {
    final stats = await getGymStats(token: token, gymId: gymId);
    return stats['coaches'] ?? 0;
  }

  Future<int> getGymClassCount({
    required String token,
    required int gymId,
  }) async {
    final stats = await getGymStats(token: token, gymId: gymId);
    return stats['classes'] ?? 0;
  }

  // Private Helpers

  Future<int> _fetchCount({
    required String token,
    required String url,
    required String field,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        return (jsonDecode(response.body)[field] as int?) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  Future<Map<String, int>> _loadGymStatsFromCache(String cacheKey) async {
    final cached = await CacheService.load(cacheKey);
    if (cached != null) {
      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      return {
        'members': decoded['members'] as int? ?? 0,
        'coaches': decoded['coaches'] as int? ?? 0,
        'classes': decoded['classes'] as int? ?? 0,
      };
    }
    return {'members': 0, 'coaches': 0, 'classes': 0};
  }
}