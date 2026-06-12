import 'dart:convert';
import '../../shared/api_constants.dart';
import 'package:http/http.dart' as http;
import '../domain/coach_profile_model.dart';

class CoachProfileRepository {
  final String baseUrl = ApiConstants.baseUrl;

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<CoachProfileModel> getProfile(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/coach/profile'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return CoachProfileModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load profile');
  }

  Future<CoachProfileModel> updateProfile(
      String token, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/coach/profile'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      return CoachProfileModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to update profile');
  }

  Future<List<String>> getSpecializations(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/coach/specializations'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return List<String>.from(jsonDecode(res.body)['specializations']);
    }
    throw Exception('Failed to load specializations');
  }
}