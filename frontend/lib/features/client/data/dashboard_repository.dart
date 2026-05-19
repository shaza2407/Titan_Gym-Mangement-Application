import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/dashboard_model.dart';
import '../../common/api_constants.dart';

class DashboardRepository {

  Future<DashboardStatsModel> getDashboardStats(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/client/dashboard-stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      return DashboardStatsModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load dashboard stats');
  }
}
