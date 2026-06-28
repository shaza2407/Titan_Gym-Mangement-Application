import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/features/shared/api_constants.dart';
import 'package:frontend/features/shared/cache_service.dart';
import 'package:frontend/features/shared/connectivity_helper.dart';
import '../domain/client_model.dart';
import '../domain/coach_model.dart';
import '../domain/admin_profile_model.dart';

class AdminRepository {
  // Cache keys
  static String _clientsKey(int gymId) => 'cache_admin_clients_$gymId';
  static String _coachesKey(int gymId) => 'cache_admin_coaches_$gymId';
  static const _profileKey = 'cache_admin_profile';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── Clients ───────────────────────────────────────────────────────────────

  Future<ClientListResponse> fetchClients(int gymId, String token) async {
    final cacheKey = _clientsKey(gymId);
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(cacheKey);
      if (cached != null) return ClientListResponse.fromJson(jsonDecode(cached));
      throw Exception('You are offline and no cached client data is available.');
    }

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/clients'),
      headers: _headers(token),
    );

    if (res.statusCode == 200) {
      await CacheService.save(cacheKey, res.body);
      return ClientListResponse.fromJson(jsonDecode(res.body));
    }

    // Server error — fall back to cache
    final cached = await CacheService.load(cacheKey);
    if (cached != null) return ClientListResponse.fromJson(jsonDecode(cached));
    throw Exception('Failed to load clients: ${res.statusCode}');
  }

  Future<void> inviteClient(
    int gymId,
    String email,
    String token, {
    String subscriptionType = 'monthly',
    int subscriptionMonths = 1,
    int subscriptionPrice = 0,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/clients/invite'),
      headers: _headers(token),
      body: jsonEncode({
        'email':               email,
        'subscription_type':   subscriptionType,
        'subscription_months': subscriptionMonths,
        'subscription_price':  subscriptionPrice,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Failed to send invite');
    }
    await CacheService.clear(_clientsKey(gymId)); // invalidate so next fetch is fresh
  }

  Future<void> cancelInvitation(int gymId, String email, String token) async {
    final res = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/invitations/$email'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Failed to cancel invitation');
    }
    await CacheService.clear(_clientsKey(gymId));
  }

  Future<void> suspendClient(int gymId, int clientId, String token) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/clients/$clientId/suspend'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Unknown error');
    }
    await CacheService.clear(_clientsKey(gymId));
  }

  Future<void> unsuspendClient(int gymId, int memberId, String token) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/clients/$memberId/unsuspend'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Failed to unsuspend');
    }
    await CacheService.clear(_clientsKey(gymId));
  }

  // ── Coaches ───────────────────────────────────────────────────────────────

  Future<CoachListResponse> fetchCoaches(int gymId, String token) async {
    final cacheKey = _coachesKey(gymId);
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(cacheKey);
      if (cached != null) return CoachListResponse.fromJson(jsonDecode(cached));
      throw Exception('You are offline and no cached coach data is available.');
    }

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/coaches'),
      headers: _headers(token),
    );

    if (res.statusCode == 200) {
      await CacheService.save(cacheKey, res.body);
      return CoachListResponse.fromJson(jsonDecode(res.body));
    }

    // Server error — fall back to cache
    final cached = await CacheService.load(cacheKey);
    if (cached != null) return CoachListResponse.fromJson(jsonDecode(cached));
    throw Exception('Failed to load coaches: ${res.statusCode}');
  }

  Future<void> inviteCoach(int gymId, String email, String token) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/coaches/invite'),
      headers: _headers(token),
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Unknown error');
    }
    await CacheService.clear(_coachesKey(gymId));
  }

  Future<void> suspendCoach(int gymId, int coachId, String token) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/coaches/$coachId/suspend'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Unknown error');
    }
    await CacheService.clear(_coachesKey(gymId));
  }

  Future<void> unsuspendCoach(int gymId, int memberId, String token) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/coaches/$memberId/unsuspend'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Failed to unsuspend');
    }
    await CacheService.clear(_coachesKey(gymId));
  }

  // ── Retention Offers ──────────────────────────────────────────────────────
  // No caching — offer eligibility changes server-side

  Future<Map<String, dynamic>> getOfferDetails(
      int gymId, int offerId, String token) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/analytics/$gymId/retention-offers/$offerId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Failed to load offer details');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Admin Profile ─────────────────────────────────────────────────────────

  Future<AdminProfile> fetchAdminProfile(String token) async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_profileKey);
      if (cached != null) return AdminProfile.fromJson(jsonDecode(cached));
      throw Exception('You are offline and no cached profile data is available.');
    }

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/profile'),
      headers: _headers(token),
    );

    if (res.statusCode == 200) {
      await CacheService.save(_profileKey, res.body);
      return AdminProfile.fromJson(jsonDecode(res.body));
    }

    // Server error — fall back to cache
    final cached = await CacheService.load(_profileKey);
    if (cached != null) return AdminProfile.fromJson(jsonDecode(cached));
    throw Exception('Failed to load profile: ${res.statusCode}');
  }

  Future<void> updateAdminProfile({
    required String token,
    required String name,
    required String phone,
    String? currentPassword,
    String? newPassword,
  }) async {
    final body = <String, dynamic>{
      if (name.isNotEmpty)  'name':  name,
      if (phone.isNotEmpty) 'phone': phone,
      if (currentPassword != null && currentPassword.isNotEmpty)
        'current_password': currentPassword,
      if (newPassword != null && newPassword.isNotEmpty)
        'new_password': newPassword,
    };

    final res = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/admin/profile'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      final detail = jsonDecode(res.body)['detail'];
      if (detail is List && detail.isNotEmpty) {
        final msg = (detail.first['message'] as String?) ??
            (detail.first['msg'] as String? ?? 'Unknown error')
                .replaceAll('Value error, ', '');
        throw Exception(msg);
      }
      throw Exception(detail ?? 'Unknown error');
    }

    await CacheService.clear(_profileKey); // invalidate so next fetch is fresh
  }

  // ── Gym Operations ────────────────────────────────────────────────────────
  // No caching — write operations only

  Future<void> updateGym({
    required int gymId,
    required String token,
    String? gymName,
    String? gymType,
    String? location,
    String? openingHours,
    String? closingHours,
    List<Map<String, dynamic>>? machines,
  }) async {
    final body = <String, dynamic>{
      if (gymName != null)      'gymName':      gymName,
      if (gymType != null)      'gymType':      gymType,
      if (location != null)     'location':     location,
      if (openingHours != null) 'openingHours': openingHours,
      if (closingHours != null) 'closingHours': closingHours,
      if (machines != null)     'machines':     machines,
    };

    final res = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/gyms/$gymId'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(jsonDecode(res.body)['detail']);
    }
  }

  Future<void> deleteGym({
    required int gymId,
    required String token,
  }) async {
    final res = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/gyms/$gymId'),
      headers: _headers(token),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(jsonDecode(res.body)['detail'] ?? 'Failed to delete gym');
    }
  }
}