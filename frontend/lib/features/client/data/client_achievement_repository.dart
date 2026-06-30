// lib/features/client/data/client_achievement_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import '../domain/achievement_model.dart';

class ClientAchievementRepository {
  static const _cacheKey = 'client_achievements';

  Future<List<AchievementModel>> getAchievements(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/achievements/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to load achievements');
      }

      await CacheService.save(_cacheKey, response.body);
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => AchievementModel.fromJson(json)).toList();
    } catch (e) {
      final cached = await CacheService.load(_cacheKey);
      if (cached != null) {
        final List<dynamic> data = json.decode(cached);
        return data.map((json) => AchievementModel.fromJson(json)).toList();
      }
      throw Exception(
        'Unable to load badges. Check your connection and try again.',
      );
    }
  }
}
