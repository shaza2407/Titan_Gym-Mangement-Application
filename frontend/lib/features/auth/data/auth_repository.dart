import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../domain/user_model.dart';

class AuthRepository {

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

  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String role,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'role': role,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['message']);
    }
  }
}
