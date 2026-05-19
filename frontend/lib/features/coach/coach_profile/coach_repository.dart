import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/features/coach/coach_profile/coach_profile_model.dart';
import '../../shared/api_constants.dart';

class CoachRepository {



  // Check if client is connected to a gym
  // Returns true/false → used right after sign in
  Future<bool> isConnectedToGym(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/client/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['is_connected'] as bool;
    }
    throw Exception('Failed to check gym connection');
  }

  // GET /client/profile
  Future<CoachProfileModel> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/client/profile'),
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

  // PUT /client/profile
  Future<CoachProfileModel> updateProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/client/profile'),
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
