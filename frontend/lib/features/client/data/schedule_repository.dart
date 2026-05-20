// lib/features/client/data/schedule_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/schedule_model.dart';

class ScheduleRepository {
  final String baseUrl = 'http://localhost:8000';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<ScheduleStatsModel> getStats(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/client/schedule/stats'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return ScheduleStatsModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load stats');
  }

  Future<List<ClassModel>> getMyClasses(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/client/schedule/my-classes'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => ClassModel.fromJson(e))
          .toList();
    }
    throw Exception('Failed to load my classes');
  }

  Future<List<ClassModel>> getUpcoming(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/client/schedule/upcoming'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => ClassModel.fromJson(e))
          .toList();
    }
    throw Exception('Failed to load upcoming');
  }

  Future<List<ClassModel>> browseClasses(String token, {String? day}) async {
    final url = day != null
        ? '$baseUrl/client/schedule/browse?day=$day'
        : '$baseUrl/client/schedule/browse';
    final res = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => ClassModel.fromJson(e))
          .toList();
    }
    throw Exception('Failed to browse classes');
  }

  Future<List<WeeklyDayModel>> getWeekly(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/client/schedule/weekly'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => WeeklyDayModel.fromJson(e))
          .toList();
    }
    throw Exception('Failed to load weekly');
  }

  Future<String> enroll(String token, int sessionId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/client/schedule/enroll/$sessionId'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['message'];
    }
    throw Exception(jsonDecode(res.body)['detail'] ?? 'Enroll failed');
  }

  Future<String> unenroll(String token, int sessionId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/client/schedule/unenroll/$sessionId'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['message'];
    }
    throw Exception(jsonDecode(res.body)['detail'] ?? 'Unenroll failed');
  }
}