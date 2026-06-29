import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/dashboard_model.dart';
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import '../../shared/connectivity_helper.dart';

class DashboardRepository {
  static const _statsKey = 'cache_client_dashboard_stats';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<DashboardStatsModel> getDashboardStats(String token) async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_statsKey);
      if (cached != null) {
        return DashboardStatsModel.fromJson(jsonDecode(cached));
      }
      throw Exception('You\'re offline and no saved dashboard data was found.');
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/client/dashboard-stats'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        await CacheService.save(_statsKey, res.body);
        return DashboardStatsModel.fromJson(jsonDecode(res.body));
      }
      final cached = await CacheService.load(_statsKey);
      if (cached != null) {
        return DashboardStatsModel.fromJson(jsonDecode(cached));
      }
      throw Exception('Unable to load dashboard data (${res.statusCode}).');
    } catch (e) {
      final cached = await CacheService.load(_statsKey);
      if (cached != null) {
        return DashboardStatsModel.fromJson(jsonDecode(cached));
      }
      throw Exception('No internet connection. Please check your network.');
    }
  }
}
