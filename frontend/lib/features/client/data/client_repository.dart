import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/client_profile_model.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ClientRepository {

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';        // Chrome / web
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';         // Android emulator
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';        // iOS simulator
    }
    return 'http://localhost:8000';
  }

  // Check if client is connected to a gym
  // Returns true/false → used right after sign in
  Future<bool> isConnectedToGym(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/client/me'),
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
  Future<ClientProfileModel> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/client/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return ClientProfileModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load profile');
  }

  // PUT /client/profile
  Future<ClientProfileModel> updateProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/client/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return ClientProfileModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update profile');
  }
}
