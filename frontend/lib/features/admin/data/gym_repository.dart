import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';

class GymModel {
  final int gymID;
  final int adminID;
  final String gymName;
  final String location;
  final String qrCode;
  final String gymType;
  final String openingHours;
  final String closingHours;

  GymModel({
    required this.gymID,
    required this.adminID,
    required this.gymName,
    required this.location,
    required this.qrCode,
    required this.gymType,
    required this.openingHours,
    required this.closingHours,
  });

  factory GymModel.fromJson(Map<String, dynamic> json) {
    return GymModel(
      gymID:                   json['gymID'],
      adminID:                 json['adminID'],
      gymName:                 json['gymName'],
      location:                json['location'],
      qrCode:                  json['QRCode'] ?? '',
      gymType:                 json['gymType'],
      openingHours:            json['openingHours'],
      closingHours:            json['closingHours'],
    );
  }
}

class GymDashboardStats {
  final int gymID;
  final String gymName;
  final int totalMembers;
  final int activeSubscriptions;
  final int todayAttendance;
  final int totalClasses;

  GymDashboardStats({
    required this.gymID,
    required this.gymName,
    required this.totalMembers,
    required this.activeSubscriptions,
    required this.todayAttendance,
    required this.totalClasses,
  });

  factory GymDashboardStats.fromJson(Map<String, dynamic> json) {
    return GymDashboardStats(
      gymID:               json['gymID'],
      gymName:             json['gymName'],
      totalMembers:        json['totalMembers'],
      activeSubscriptions: json['activeSubscriptions'],
      todayAttendance:     json['todayAttendance'],
      totalClasses:        (json['totalClasses'] ?? 0) as int,
    );
  }
}

class GymRepository {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // GET /gyms/
  Future<List<GymModel>> getGyms({required String token}) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/gyms/'),
      headers: _headers(token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => GymModel.fromJson(e)).toList();
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  // GET /gyms/{id}/dashboard
  Future<GymDashboardStats> getDashboardStats({
    required String token,
    required int gymId,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/gyms/$gymId/dashboard'),
      headers: _headers(token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return GymDashboardStats.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  // POST /gyms/
Future<GymModel> createGym({
    required String token,
    required String gymName,
    required String location,
    required String gymType,
    required String openingHours,
    required String closingHours,
    List<Map<String, dynamic>> machines = const [],

  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/gyms/'),
      headers: _headers(token),
      body: jsonEncode({
        'gymName':                   gymName,
        'location':                  location,
        'gymType':                   gymType,
        'openingHours':              openingHours,
        'closingHours':              closingHours,
        'machines': machines, 

      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return GymModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

// GET /admin/gyms/total-members
Future<int> getTotalMembers({required String token}) async {
  final response = await http.get(
    Uri.parse('${ApiConstants.baseUrl}/admin/gyms/total-members'),
    headers: _headers(token),
  );
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return jsonDecode(response.body)['total'];
  } else {
    throw Exception(jsonDecode(response.body)['error getting total members ']);
  }
}

Future<int> getGymMemberCount({
  required String token,
  required int gymId,
}) async {
  final response = await http.get(
    Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/member-count'),
    headers: _headers(token),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body)['count'] as int;
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
    return jsonDecode(response.body)['count'] as int;
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
    return jsonDecode(response.body)['count'] as int;
  }
  return 0;
}
}
