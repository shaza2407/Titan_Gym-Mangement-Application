import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/auth_model.dart';
import '../domain/user_model.dart';
import '../domain/i_auth_repository.dart';
import '../../shared/api_constants.dart';

class AuthRepository implements IAuthRepository {
  final String _base = ApiConstants.baseUrl;

  Map<String, dynamic> _decode(http.Response res) => jsonDecode(res.body);

  void _throwIfError(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    final body   = _decode(res);
    final detail = body['detail'];

    if (detail is List && detail.isNotEmpty) {
      final msg = (detail.first['msg'] as String).replaceAll('Value error, ', '');
      throw Exception(msg);
    }

    throw Exception(detail ?? body['message'] ?? 'Request failed (${res.statusCode})');
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) =>
      http.post(
        Uri.parse('$_base$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

  Future<http.Response> _get(String path, String token) =>
      http.get(
        Uri.parse('$_base$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

  @override
  Future<UserModel> signUp(SignUpRequest request) async {
    final res = await _post('/auth/signup', request.toJson());
    _throwIfError(res);
    return UserModel.fromJson(_decode(res));
  }

  @override
  Future<void> verifyEmail(VerifyEmailRequest request) async {
    final res = await _post('/auth/verify-email', request.toJson());
    _throwIfError(res);
  }

  @override
  Future<void> resendVerification(String email) async {
    final res = await _post('/auth/resend-verification', {'email': email});
    _throwIfError(res);
  }

  @override
  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    final res = await _post('/auth/forgot-password', request.toJson());
    _throwIfError(res);
  }

  @override
  Future<void> resetPassword(ResetPasswordRequest request) async {
    final res = await _post('/auth/reset-password', request.toJson());
    _throwIfError(res);
  }

  @override
  Future<LoginResponse> signIn(LoginRequest request) async {
    final res = await _post('/auth/signin', request.toJson());
    _throwIfError(res);
    return LoginResponse.fromJson(_decode(res));
  }

  @override
  Future<ClientProfileResponse> getClientProfile(String token) async {
    final res = await _get('/client/me', token);
    _throwIfError(res);
    return ClientProfileResponse.fromJson(_decode(res));
  }
}