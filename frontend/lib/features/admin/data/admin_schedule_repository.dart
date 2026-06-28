// lib/features/admin/data/admin_schedule_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/schedule_model.dart';
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import '../../shared/connectivity_helper.dart';

class AdminScheduleRepository {
  static String _statsKey(int gymId)        => 'cache_schedule_stats_$gymId';
  static String _classesKey(int gymId)      => 'cache_schedule_classes_$gymId';
  static String _coachesKey(int gymId)      => 'cache_schedule_coaches_$gymId';
  static String _requestsKey(int gymId)     => 'cache_schedule_requests_$gymId';
  static String _membersKey(int sessionId)  => 'cache_schedule_members_$sessionId';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<AdminScheduleStatsModel> getStats(
    String token,
    int gymId, {
    bool weekOnly = false,
  }) async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_statsKey(gymId));
      if (cached != null) return AdminScheduleStatsModel.fromJson(jsonDecode(cached));
      throw Exception('You are offline and no cached schedule stats available.');
    }

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/schedule/stats?gym_id=$gymId&week_only=$weekOnly'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      await CacheService.save(_statsKey(gymId), res.body);
      return AdminScheduleStatsModel.fromJson(jsonDecode(res.body));
    }

    final cached = await CacheService.load(_statsKey(gymId));
    if (cached != null) return AdminScheduleStatsModel.fromJson(jsonDecode(cached));
    throw Exception('Failed to load schedule stats');
  }

  Future<List<ClassSessionModel>> getClasses(
    String token,
    int gymId, {
    String? fromDate,
    String? weekStart,
    String? weekEnd,
  }) async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_classesKey(gymId));
      if (cached != null) {
        final data = jsonDecode(cached) as List;
        return data.map((e) => ClassSessionModel.fromJson(e)).toList();
      }
      throw Exception('You are offline and no cached classes available.');
    }

    final params = <String>[];
    if (fromDate != null)  params.add('from_date=$fromDate');
    if (weekStart != null) params.add('week_start=$weekStart');
    if (weekEnd != null)   params.add('week_end=$weekEnd');
    final query = params.isNotEmpty ? '&${params.join('&')}' : '';

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/schedule/classes?gym_id=$gymId$query'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      await CacheService.save(_classesKey(gymId), res.body);
      final data = jsonDecode(res.body) as List;
      return data.map((e) => ClassSessionModel.fromJson(e)).toList();
    }

    final cached = await CacheService.load(_classesKey(gymId));
    if (cached != null) {
      final data = jsonDecode(cached) as List;
      return data.map((e) => ClassSessionModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load classes');
  }

  // ── Write operations — no caching, invalidate on success ─────────────────

  Future<void> createClass(String token, int gymId, Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/schedule/classes?gym_id=$gymId'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) {
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Failed to create class');
    }
    await CacheService.clear(_classesKey(gymId));
    await CacheService.clear(_statsKey(gymId));
  }

  Future<void> editClass(String token, int gymId, int sessionId, Map<String, dynamic> payload) async {
    final res = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/admin/schedule/classes/$sessionId?gym_id=$gymId'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Failed to update class');
    }
    await CacheService.clear(_classesKey(gymId));
    await CacheService.clear(_membersKey(sessionId));
  }

  Future<void> deleteClass(String token, int gymId, int sessionId) async {
    final res = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/admin/schedule/classes/$sessionId?gym_id=$gymId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Failed to delete class');
    }
    await CacheService.clear(_classesKey(gymId));
    await CacheService.clear(_statsKey(gymId));
    await CacheService.clear(_membersKey(sessionId));
  }

  Future<List<ClassMemberModel>> getClassMembers(
    String token,
    int gymId,
    int sessionId, {
    String? classDate,
  }) async {
    final isOnline = await ConnectivityHelper.isOnline();
    if (!isOnline) {
      final cached = await CacheService.load(_membersKey(sessionId));
      if (cached != null) {
        final data = jsonDecode(cached) as List;
        return data.map((e) => ClassMemberModel.fromJson(e)).toList();
      }
      throw Exception('You are offline and no cached class members available.');
    }

    final query = classDate != null ? '&class_date=$classDate' : '';
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/schedule/classes/$sessionId/members?gym_id=$gymId$query'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final membersBody = jsonEncode(jsonDecode(res.body)['members']);
      await CacheService.save(_membersKey(sessionId), membersBody);
      final data = jsonDecode(res.body)['members'] as List;
      return data.map((e) => ClassMemberModel.fromJson(e)).toList();
    }

    final cached = await CacheService.load(_membersKey(sessionId));
    if (cached != null) {
      final data = jsonDecode(cached) as List;
      return data.map((e) => ClassMemberModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load class members');
  }

  Future<List<ClassRequestModel>> getPendingRequests(String token, int gymId) async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_requestsKey(gymId));
      if (cached != null) {
        final data = jsonDecode(cached) as List;
        return data.map((e) => ClassRequestModel.fromJson(e)).toList();
      }
      throw Exception('You are offline and no cached requests available.');
    }

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/schedule/requests?gym_id=$gymId'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      await CacheService.save(_requestsKey(gymId), res.body);
      final data = jsonDecode(res.body) as List;
      return data.map((e) => ClassRequestModel.fromJson(e)).toList();
    }

    final cached = await CacheService.load(_requestsKey(gymId));
    if (cached != null) {
      final data = jsonDecode(cached) as List;
      return data.map((e) => ClassRequestModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load requests');
  }

  Future<void> approveRequest(String token, int gymId, int requestId) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/schedule/requests/$requestId/approve?gym_id=$gymId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Failed to approve request');
    }
    await CacheService.clear(_requestsKey(gymId));
    await CacheService.clear(_classesKey(gymId));
  }

  Future<void> rejectRequest(String token, int gymId, int requestId) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/schedule/requests/$requestId/reject?gym_id=$gymId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Failed to reject request');
    }
    await CacheService.clear(_requestsKey(gymId));
  }

  Future<List<CoachOptionModel>> getCoaches(String token, int gymId) async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_coachesKey(gymId));
      if (cached != null) {
        final data = jsonDecode(cached) as List;
        return data.map((e) => CoachOptionModel.fromJson(e)).toList();
      }
      throw Exception('You are offline and no cached coaches available.');
    }

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/schedule/coaches?gym_id=$gymId'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      await CacheService.save(_coachesKey(gymId), res.body);
      final data = jsonDecode(res.body) as List;
      return data.map((e) => CoachOptionModel.fromJson(e)).toList();
    }

    final cached = await CacheService.load(_coachesKey(gymId));
    if (cached != null) {
      final data = jsonDecode(cached) as List;
      return data.map((e) => CoachOptionModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load coaches');
  }
}