import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/features/coach/coach_profile/coach_profile_model.dart';
import '../../shared/api_constants.dart';

class CoachRepository {
  Future<bool> isConnectedToGym(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/coach/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      // Coaches don't need gym connection check, they're always "connected"
      return true;
    }
    throw Exception('Failed to check gym connection');
  }

  // GET /coach/profile
  Future<CoachProfileModel> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/coach/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return CoachProfileModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load profile');
  }

  // PUT /coach/profile
  Future<CoachProfileModel> updateProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/coach/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return CoachProfileModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update profile');
  }
}
