import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/user_model.dart';

class AuthRepository {
  final String baseUrl = 'http://10.0.2.2:8000';

  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String role,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
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