import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import '../domain/coach_schedule_model.dart';

class CoachScheduleRepository {
  final String baseUrl = ApiConstants.baseUrl;

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<CoachScheduleStatsModel> getStats(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/coach/schedule/stats'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return CoachScheduleStatsModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load schedule stats');
  }

  Future<List<CoachWeeklyDayModel>> getWeekly(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/coach/schedule/weekly'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => CoachWeeklyDayModel.fromJson(e))
          .toList();
    }
    throw Exception('Failed to load weekly schedule');
  }

  Future<List<CoachClassModel>> getMyClasses(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/coach/schedule/my-classes'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => CoachClassModel.fromJson(e))
          .toList();
    }
    throw Exception('Failed to load my classes');
  }

  Future<List<CoachClassRequestModel>> getRequests(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/coach/schedule/requests'),
      headers: _headers(token),
    );

    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => CoachClassRequestModel.fromJson(e))
          .toList();
    }
    throw Exception('Failed to load requests');
  }

  Future<String> createRequest(String token, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/coach/schedule/requests'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) {
      return jsonDecode(res.body)['message'];
    }
    throw Exception(
      jsonDecode(res.body)['detail'] ?? 'Failed to create request',
    );
  }

  Future<void> removeClass(String token, int classId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/coach/schedule/my-classes/$classId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove class');
    }
  }
}
