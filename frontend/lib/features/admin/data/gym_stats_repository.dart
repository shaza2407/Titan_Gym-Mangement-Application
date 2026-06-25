import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';

class GymStatsRepository {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<int> getTotalMembers({required String token}) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/gyms/total-members'),
      headers: _headers(token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (jsonDecode(response.body)['total'] as int?) ?? 0;
    }
    return 0;
  }

  Future<int> getGymMemberCount({
    required String token,
    required int gymId,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/gyms/$gymId/member-count'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body)['count'] as int?) ?? 0;
    }
    return 0;
  }

  Future<int> getGymCoachCount({
    required String token,
    required int gymId,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/gyms/$gymId/coach-count'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body)['count'] as int?) ?? 0;
    }
    return 0;
  }

  Future<int> getGymClassCount({
    required String token,
    required int gymId,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/gyms/$gymId/class-count'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body)['count'] as int?) ?? 0;
    }
    return 0;
  }
}