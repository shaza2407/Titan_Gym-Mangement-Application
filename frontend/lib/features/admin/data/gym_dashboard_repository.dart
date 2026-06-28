import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/gym_model.dart';
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import '../../shared/connectivity_helper.dart';

class GymDashboardRepository {
  static String _cacheKey(int gymId) => 'cache_gym_dashboard_$gymId';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<GymDashboardStats> getDashboardStats({
    required String token,
    required int gymId,
  }) async {
    final cacheKey = _cacheKey(gymId);
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(cacheKey);
      if (cached != null) return GymDashboardStats.fromJson(jsonDecode(cached));
      throw Exception('You are offline and no cached data is available.');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/gyms/$gymId/dashboard'),
      headers: _headers(token),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await CacheService.save(cacheKey, response.body);
      return GymDashboardStats.fromJson(jsonDecode(response.body));
    }

    //if server error — fall back to cache
    final cached = await CacheService.load(cacheKey);
    if (cached != null) return GymDashboardStats.fromJson(jsonDecode(cached));

    throw Exception(jsonDecode(response.body)['detail']);
  }
}