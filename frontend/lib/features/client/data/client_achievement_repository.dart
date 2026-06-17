// lib/features/client/data/client_achievement_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import '../domain/achievement_model.dart';

class ClientAchievementRepository {
  Future<List<AchievementModel>> getAchievements(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/achievements/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => AchievementModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load achievements');
    }
  }
}
