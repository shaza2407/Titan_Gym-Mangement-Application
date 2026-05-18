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
      //like schema
      body: jsonEncode({
        'name': fullName,
        'email': email,
        'phone': phoneNumber,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else { print('STATUS: ${response.statusCode}');
        print('STATUS: ${response.statusCode}');
        print('BODY: ${response.body}');
        throw Exception(jsonDecode(response.body)['detail'] ?? jsonDecode(response.body)['message']);
    }
  }

Future<void> verifyEmail({
  required String email,
  required String code,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/verify-email'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'code': code,
    }),
  );

  if (response.statusCode >= 200 && response.statusCode < 300) {
    return;
  } else {
    final body = jsonDecode(response.body);
    throw Exception(body['detail'] ?? body['message']);
  }
}

Future<void> resendVerification({required String email}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/resend-verification'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email}),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    final body = jsonDecode(response.body);
    throw Exception(body['detail'] ?? body['message']);
  }
}

Future<void> forgotPassword({required String email}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/forgot-password'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email}),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    final body = jsonDecode(response.body);
    throw Exception(body['detail'] ?? body['message']);
  }
}

Future<void> resetPassword({
  required String email,
  required String code,
  required String newPassword,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/reset-password'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'code': code,
      'new_password': newPassword,
    }),
  );

  if (response.statusCode >= 200 && response.statusCode < 300) {
    return;
  } else {
    final body = jsonDecode(response.body);
    throw Exception(body['detail'] ?? body['message']);
  }
}

}
