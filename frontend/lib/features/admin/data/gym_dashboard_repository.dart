import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/gym_model.dart';
import '../../shared/api_constants.dart';

class GymDashboardRepository {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

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
}