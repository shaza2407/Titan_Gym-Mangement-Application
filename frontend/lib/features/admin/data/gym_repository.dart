import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import '../../shared/connectivity_helper.dart';
import '../../shared/cache_service.dart';
import 'package:frontend/features/admin/domain/gym_model.dart';

class GymRepository {
  static const _gymsListKey = 'cache_gyms_list';
  static const _totalMembersKey = 'cache_gym_total_members';
  static String _dashboardKey(int gymId) => 'cache_gym_dashboard_$gymId';
  static String _gymStatsKey(int gymId) => 'cache_gym_stats_$gymId';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // GET /gyms/
  Future<List<GymModel>> getGyms({required String token}) async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_gymsListKey);
      if (cached != null) {
        final List decoded = jsonDecode(cached);
        return decoded.map((e) => GymModel.fromJson(e)).toList();
      }
      return [];
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/gyms/'),
      headers: _headers(token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      await CacheService.save(_gymsListKey, jsonEncode(data));
      return data.map((e) => GymModel.fromJson(e)).toList();
    } else {
      // Server error — try cache before throwing
      final cached = await CacheService.load(_gymsListKey);
      if (cached != null) {
        final List decoded = jsonDecode(cached);
        return decoded.map((e) => GymModel.fromJson(e)).toList();
      }
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  // GET /gyms/{id}/dashboard
  Future<GymDashboardStats> getDashboardStats({
    required String token,
    required int gymId,
  }) async {
    final cacheKey = _dashboardKey(gymId);
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(cacheKey);
      if (cached != null) return GymDashboardStats.fromJson(jsonDecode(cached));
      throw Exception('No internet and no cached dashboard data.');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/gyms/$gymId/dashboard'),
      headers: _headers(token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      await CacheService.save(cacheKey, jsonEncode(data));
      return GymDashboardStats.fromJson(data);
    } else {
      final cached = await CacheService.load(cacheKey);
      if (cached != null) return GymDashboardStats.fromJson(jsonDecode(cached));
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  // POST /gyms/ — no caching (write operation), invalidates gyms list
  Future<GymModel> createGym({
    required String token,
    required String gymName,
    required String location,
    required String gymType,
    required String openingHours,
    required String closingHours,
    List<Map<String, dynamic>> machines = const [],
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/gyms/'),
      headers: _headers(token),
      body: jsonEncode({
        'gymName': gymName,
        'location': location,
        'gymType': gymType,
        'openingHours': openingHours,
        'closingHours': closingHours,
        'machines': machines,
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      await CacheService.clear(_gymsListKey); // invalidate so list refreshes
      return GymModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  // GET /gyms/total-members
  Future<int> getTotalMembers({required String token}) async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_totalMembersKey);
      return int.tryParse(cached ?? '') ?? 0;
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/gyms/total-members'),
      headers: _headers(token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final total = jsonDecode(response.body)['total'] as int;
      await CacheService.save(_totalMembersKey, total.toString());
      return total;
    } else {
      final cached = await CacheService.load(_totalMembersKey);
      if (cached != null) return int.tryParse(cached) ?? 0;
      throw Exception(jsonDecode(response.body)['error getting total members ']);
    }
  }

  // GET /gyms/{id}/member-count + coach-count + class-count
  // All three are batched into one cache entry per gym
  Future<Map<String, int>> _getGymCounts({
    required String token,
    required int gymId,
  }) async {
    final cacheKey = _gymStatsKey(gymId);
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(cacheKey);
      if (cached != null) {
        final Map<String, dynamic> decoded = jsonDecode(cached);
        return {
          'members': decoded['members'] as int? ?? 0,
          'coaches': decoded['coaches'] as int? ?? 0,
          'classes': decoded['classes'] as int? ?? 0,
        };
      }
      return {'members': 0, 'coaches': 0, 'classes': 0};
    }

    final results = await Future.wait([
      http.get(Uri.parse('${ApiConstants.baseUrl}/gyms/$gymId/member-count'), headers: _headers(token)),
      http.get(Uri.parse('${ApiConstants.baseUrl}/gyms/$gymId/coach-count'),  headers: _headers(token)),
      http.get(Uri.parse('${ApiConstants.baseUrl}/gyms/$gymId/class-count'),  headers: _headers(token)),
    ]);

    final counts = {
      'members': results[0].statusCode == 200 ? jsonDecode(results[0].body)['count'] as int : 0,
      'coaches': results[1].statusCode == 200 ? jsonDecode(results[1].body)['count'] as int : 0,
      'classes': results[2].statusCode == 200 ? jsonDecode(results[2].body)['count'] as int : 0,
    };

    await CacheService.save(cacheKey, jsonEncode(counts));
    return counts;
  }

  Future<int> getGymMemberCount({required String token, required int gymId}) async {
    return (await _getGymCounts(token: token, gymId: gymId))['members'] ?? 0;
  }

  Future<int> getGymCoachCount({required String token, required int gymId}) async {
    return (await _getGymCounts(token: token, gymId: gymId))['coaches'] ?? 0;
  }

  Future<int> getGymClassCount({required String token, required int gymId}) async {
    return (await _getGymCounts(token: token, gymId: gymId))['classes'] ?? 0;
  }
}