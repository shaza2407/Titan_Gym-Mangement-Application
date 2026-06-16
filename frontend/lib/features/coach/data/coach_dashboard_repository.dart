import 'dart:convert';
import '../../shared/api_constants.dart';
import 'package:http/http.dart' as http;
import '../domain/coach_dashboard_model.dart';

class CoachDashboardRepository {
  final String baseUrl = ApiConstants.baseUrl;

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<CoachDashboardStatsModel> getStats(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/coach/dashboard'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return CoachDashboardStatsModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load dashboard stats');
  }

  Future<List<CoachUpcomingClassModel>> getUpcoming(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/coach/dashboard/upcoming'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => CoachUpcomingClassModel.fromJson(e))
          .toList();
    }
    throw Exception('Failed to load upcoming classes');
  }
}
