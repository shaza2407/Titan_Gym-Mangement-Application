import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/features/shared/api_constants.dart';

// 1- Client Models

class ClientListItem {
  final int id;
  final String name, email, status; // "active" | "pending" | "expired"
  final String? phone, subscription, subscriptionEnd, joined, invitationSent;
  final int? visits;

  ClientListItem({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.phone,
    this.subscription,
    this.subscriptionEnd,
    this.visits,
    this.joined,
    this.invitationSent,
  });

  factory ClientListItem.fromJson(Map<String, dynamic> json) {
    return ClientListItem(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'pending',
      phone: json['phone'],
      subscription: json['subscription'],
      subscriptionEnd: json['subscription_end'],
      visits: json['visits'],
      joined: json['joined'],
      invitationSent: json['invitation_sent'],
    );
  }
}

class ClientListResponse {
  final int total, active, pending, expired;
  final List<ClientListItem> members;

  ClientListResponse({
    required this.total,
    required this.active,
    required this.pending,
    required this.expired,
    required this.members,
  });

  factory ClientListResponse.fromJson(Map<String, dynamic> json) {
    return ClientListResponse(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      pending: json['pending'] ?? 0,
      expired: json['expired'] ?? 0,
      members: (json['members'] as List<dynamic>? ?? [])
          .map((m) => ClientListItem.fromJson(m))
          .toList(),
    );
  }
}

// 2- Coach Models

class CoachListItem {
  final int id;
  final String name, email, status; // "active" | "pending" | "suspended"
  final String? phone, hireDate, invitationSent;

  CoachListItem({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.phone,
    this.hireDate,
    this.invitationSent,
  });

  factory CoachListItem.fromJson(Map<String, dynamic> json) {
    return CoachListItem(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'pending',
      phone: json['phone'],
      hireDate: json['hire_date'],
      invitationSent: json['invitation_sent'],
    );
  }
}

class CoachListResponse {
  final int total, active, pending;
  final List<CoachListItem> coaches;

  CoachListResponse({
    required this.total,
    required this.active,
    required this.pending,
    required this.coaches,
  });

  factory CoachListResponse.fromJson(Map<String, dynamic> json) {
    return CoachListResponse(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      pending: json['pending'] ?? 0,
      coaches: (json['coaches'] as List<dynamic>? ?? [])
          .map((c) => CoachListItem.fromJson(c))
          .toList(),
    );
  }
}

class AdminApiService {
  // Clients

  static Future<ClientListResponse> fetchClients(int gymId, String token) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/clients'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      return ClientListResponse.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load clients: ${res.statusCode}');
  }

  static Future<void> inviteClient(
  int gymId,
  String email,
  String token, {
  String subscriptionType = 'monthly',
  int subscriptionMonths = 1,
  }) async {
  final res = await http.post(
    Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/clients/invite'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': email,
      'subscription_type': subscriptionType,
      'subscription_months': subscriptionMonths,
    }),
  );
  if (res.statusCode != 201) {
    throw Exception(jsonDecode(res.body)['detail'] ?? 'Failed to send invite');
  }
}

  static Future<void> suspendClient(int gymId, int clientId, String token) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/clients/$clientId/suspend'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      final detail = jsonDecode(res.body)['detail'] ?? 'Unknown error';
      throw Exception(detail);
    }
  }


  // Coaches
  static Future<CoachListResponse> fetchCoaches(int gymId, String token) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/coaches'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      return CoachListResponse.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load coaches: ${res.statusCode}');
  }

  static Future<void> inviteCoach(int gymId, String email, String token) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/coaches/invite'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final detail = jsonDecode(res.body)['detail'] ?? 'Unknown error';
      throw Exception(detail);
    }
  }

  static Future<void> suspendCoach(int gymId, int coachId, String token) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/coaches/$coachId/suspend'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      final detail = jsonDecode(res.body)['detail'] ?? 'Unknown error';
      throw Exception(detail);
    }
  }

// Admin Profile
static Future<AdminProfile> fetchAdminProfile(String token) async {
  final res = await http.get(
    Uri.parse('${ApiConstants.baseUrl}/admin/profile'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  if (res.statusCode == 200) {
    return AdminProfile.fromJson(jsonDecode(res.body));
  }
  throw Exception('Failed to load profile: ${res.statusCode}');
}

static Future<void> updateAdminProfile({
  required String token,
  required String name,
  required String phone,
  String? currentPassword,
  String? newPassword,
}) async {
  final body = {
    'name': name,
    'phone': phone,
    if (currentPassword != null && currentPassword.isNotEmpty)
      'current_password': currentPassword,
    if (newPassword != null && newPassword.isNotEmpty)
      'new_password': newPassword,
  };

  final res = await http.put(
    Uri.parse('${ApiConstants.baseUrl}/admin/profile'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(body),
  );
  if (res.statusCode != 200) {
    final detail = jsonDecode(res.body)['detail'] ?? 'Unknown error';
    throw Exception(detail);
  }
}

static Future<void> updateGym({
  required int gymId,
  required String token,
  required String gymName,
  required String gymType,
  required String location,
  required String openingHours,
  required String closingHours,
  required double subscriptionPrice,
  double? yearlySubscriptionPrice,
}) async {
  final res = await http.patch(
    Uri.parse('${ApiConstants.baseUrl}/gyms/$gymId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'gymName': gymName,
      'gymType': gymType,
      'location': location,
      'openingHours': openingHours,
      'closingHours': closingHours,
      'subscriptionPrice': subscriptionPrice,
      'yearlySubscriptionPrice': yearlySubscriptionPrice,
    }),
  );
  if (res.statusCode != 200) {
    throw Exception(jsonDecode(res.body)['detail'] ?? 'Failed to update gym');
  }
}

}

//admin profile models
class AdminProfile {
  final int adminID;
  final int userID;
  final String name;
  final String email;
  final String? phone;
  final String? createdAt;
  final int totalGyms;

  AdminProfile({
    required this.adminID,
    required this.userID,
    required this.name,
    required this.email,
    this.phone,
    this.createdAt,
    this.totalGyms = 0,
  });

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      adminID:    json['adminID'],
      userID:     json['userID'],
      name:       json['name']       ?? '',
      email:      json['email']      ?? '',
      phone:      json['phone'],
      createdAt:  json['created_at'],
      totalGyms:  json['total_gyms'] ?? 0,
    );
  }
}

