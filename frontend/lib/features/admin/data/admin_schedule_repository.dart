// lib/features/admin/data/admin_schedule_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/schedule_model.dart';
import '../../shared/api_constants.dart';

class AdminScheduleRepository {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<AdminScheduleStatsModel> getStats(
    String token,
    int gymId, {
    bool weekOnly = false,
  }) async {
    final res = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/admin/schedule/stats?gym_id=$gymId&week_only=$weekOnly',
      ),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return AdminScheduleStatsModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load schedule stats');
  }

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
        '${ApiConstants.baseUrl}/admin/schedule/classes?gym_id=$gymId$query',
      ),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      return data.map((e) => ClassSessionModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load classes');
  }

  Future<void> createClass(
    String token,
    int gymId,
    Map<String, dynamic> payload,
  ) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/schedule/classes?gym_id=$gymId'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) {
      throw Exception(
        jsonDecode(res.body)['detail'] ?? 'Failed to create class',
      );
    }
  }

  Future<void> editClass(
    String token,
    int gymId,
    int sessionId,
    Map<String, dynamic> payload,
  ) async {
    final res = await http.put(
      Uri.parse(
        '${ApiConstants.baseUrl}/admin/schedule/classes/$sessionId?gym_id=$gymId',
      ),
      headers: _headers(token),
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception(
        jsonDecode(res.body)['detail'] ?? 'Failed to update class',
      );
    }
  }

  Future<void> deleteClass(String token, int gymId, int sessionId) async {
    final res = await http.delete(
      Uri.parse(
        '${ApiConstants.baseUrl}/admin/schedule/classes/$sessionId?gym_id=$gymId',
      ),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception(
        jsonDecode(res.body)['detail'] ?? 'Failed to delete class',
      );
    }
  }

  Future<List<ClassMemberModel>> getClassMembers(
    String token,
    int gymId,
    int sessionId, {
    String? classDate,
  }) async {
    final query = classDate != null ? '&class_date=$classDate' : '';
    final res = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/admin/schedule/classes/$sessionId/members?gym_id=$gymId$query',
      ),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['members'] as List;
      return data.map((e) => ClassMemberModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load class members');
  }

  Future<List<ClassRequestModel>> getPendingRequests(
    String token,
    int gymId,
  ) async {
    final res = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/admin/schedule/requests?gym_id=$gymId',
      ),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      return data.map((e) => ClassRequestModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load requests');
  }

  Future<void> approveRequest(String token, int gymId, int requestId) async {
    final res = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/admin/schedule/requests/$requestId/approve?gym_id=$gymId',
      ),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception(
        jsonDecode(res.body)['detail'] ?? 'Failed to approve request',
      );
    }
  }

  Future<void> rejectRequest(String token, int gymId, int requestId) async {
    final res = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/admin/schedule/requests/$requestId/reject?gym_id=$gymId',
      ),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception(
        jsonDecode(res.body)['detail'] ?? 'Failed to reject request',
      );
    }
  }

  Future<List<CoachOptionModel>> getCoaches(String token, int gymId) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/schedule/coaches?gym_id=$gymId'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      return data.map((e) => CoachOptionModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load coaches');
  }
}
