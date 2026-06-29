import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/client_profile_model.dart';
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import '../../shared/connectivity_helper.dart';

class ClientRepository {
  static const _profileKey = 'cache_client_profile';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<bool> isConnectedToGym(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/client/me'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['is_connected'] as bool;
      }
      throw Exception('Failed to check gym connection');
    } catch (e) {
      throw Exception('No internet connection. Please check your network.');
    }
  }

  Future<ClientProfileModel> getProfile(String token) async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_profileKey);
      if (cached != null) {
        return ClientProfileModel.fromJson(jsonDecode(cached));
      }
      throw Exception('You\'re offline and no saved profile was found.');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/client/profile'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        await CacheService.save(_profileKey, response.body);
        return ClientProfileModel.fromJson(jsonDecode(response.body));
      }
      final cached = await CacheService.load(_profileKey);
      if (cached != null) {
        return ClientProfileModel.fromJson(jsonDecode(cached));
      }
      throw Exception('Unable to load profile (${response.statusCode}).');
    } catch (e) {
      final cached = await CacheService.load(_profileKey);
      if (cached != null) {
        return ClientProfileModel.fromJson(jsonDecode(cached));
      }
      throw Exception('You\'re offline and no saved profile was found.');
    }
  }

  Future<ClientProfileModel> updateProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    final isOnline = await ConnectivityHelper.isOnline();
    if (!isOnline) {
      throw Exception(
        'You\'re offline. Connect to the internet to save changes.',
      );
    }

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/client/profile'),
        headers: _headers(token),
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        await CacheService.save(_profileKey, response.body);
        return ClientProfileModel.fromJson(jsonDecode(response.body));
      }
      final detail = jsonDecode(response.body)['detail'];
      if (detail is List && detail.isNotEmpty) {
        final msg =
            (detail.first['message'] as String?) ??
            (detail.first['msg'] as String? ?? 'Unknown error').replaceAll(
              'Value error, ',
              '',
            );
        throw Exception(msg);
      }
      throw Exception(detail ?? 'Failed to update profile.');
    } catch (e) {
      rethrow;
    }
  }
}
