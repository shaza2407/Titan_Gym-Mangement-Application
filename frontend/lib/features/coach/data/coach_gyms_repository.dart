import 'dart:convert';
import 'package:frontend/features/admin/domain/schedule_model.dart';

import '../../shared/api_constants.dart';
import 'package:http/http.dart' as http;
import '../domain/coach_gyms_model.dart';

class CoachGymsRepository {
  final String baseUrl = ApiConstants.baseUrl;

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<CoachGymModel>> getCoachGyms(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/coach/gyms/my-gyms'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => CoachGymModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<CoachAnnouncementModel>> getGymAnnouncements(
    String token, {
    int? gymId,
  }) async {
    final query = gymId != null ? '?gym_id=$gymId' : '';
    final res = await http.get(
      Uri.parse('$baseUrl/coach/gyms/my-announcements$query'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => CoachAnnouncementModel.fromJson(e)).toList();
    }
    return [];
  }
}

class GymScheduleRepository {
  final String baseUrl = ApiConstants.baseUrl;

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<ClassSessionModel>> getClasses(
    String token,
    int gymId, {
    String? fromDate,
    String? weekStart,
    String? weekEnd,
  }) async {
    final params = <String>[];
    if (fromDate != null) params.add('from_date=$fromDate');
    if (weekStart != null) params.add('week_start=$weekStart');
    if (weekEnd != null) params.add('week_end=$weekEnd');
    final query = params.isNotEmpty ? '&${params.join('&')}' : '';

    final res = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/coach/gyms/classes?gym_id=$gymId$query',
      ),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      return data.map((e) => ClassSessionModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load classes');
  }
}
