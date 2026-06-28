import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import '../../shared/connectivity_helper.dart';
import '../domain/renew_membership_model.dart';

class RenewMembershipRepository {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<void> renewMembership({
    required String token,
    required int gymId,
    required int memberId,
    required RenewMembershipRequest request,
  }) async {
    final isOnline = await ConnectivityHelper.isOnline();
    if (!isOnline) {
      throw Exception('You are offline. Please try again when you\'re connected.');
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/gyms/$gymId/clients/$memberId/renew'),
      headers: _headers(token),
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception(
        jsonDecode(response.body)['detail'] ?? 'Failed to renew membership',
      );
    }
  }
}