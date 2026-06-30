import 'dart:convert';
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import 'package:http/http.dart' as http;
import '../domain/coach_profile_model.dart';

class CoachProfileRepository {
  final String baseUrl = ApiConstants.baseUrl;

  static const _profileCacheKey = 'coach_profile';
  static const _specializationsCacheKey = 'coach_specializations';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<CoachProfileModel> getProfile(String token) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/coach/profile'), headers: _headers(token))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('Failed to load profile');
      await CacheService.save(_profileCacheKey, res.body);
      return CoachProfileModel.fromJson(jsonDecode(res.body));
    } catch (e) {
      final cached = await CacheService.load(_profileCacheKey);
      if (cached != null) return CoachProfileModel.fromJson(jsonDecode(cached));
      throw Exception('Unable to load your profile. Check your connection.');
    }
  }

  Future<List<String>> getSpecializations(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/coach/specializations'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('Failed to load specializations');
      }
      await CacheService.save(_specializationsCacheKey, res.body);
      return List<String>.from(jsonDecode(res.body)['specializations']);
    } catch (e) {
      final cached = await CacheService.load(_specializationsCacheKey);
      if (cached != null) {
        return List<String>.from(jsonDecode(cached)['specializations']);
      }
      throw Exception('Unable to load specializations. Check your connection.');
    }
  }

  Future<CoachProfileModel> updateProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    http.Response res;
    try {
      res = await http
          .put(
            Uri.parse('$baseUrl/coach/profile'),
            headers: _headers(token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw Exception(
        'Could not save changes — check your connection and try again.',
      );
    }

    if (res.statusCode == 200) {
      return CoachProfileModel.fromJson(jsonDecode(res.body));
    }

    try {
      final body = jsonDecode(res.body);
      final detail = body['detail'];
      if (detail is List && detail.isNotEmpty) {
        final msg = (detail.first['msg'] as String).replaceAll(
          'Value error, ',
          '',
        );
        throw Exception(msg);
      } else if (detail is String) {
        throw Exception(detail);
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }

    throw Exception('Failed to update profile');
  }
}
