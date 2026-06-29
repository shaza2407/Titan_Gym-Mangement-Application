import 'package:flutter/material.dart';
import '../../domain/auth_model.dart';
import '../../domain/i_auth_repository.dart';
import '../../data/auth_repository.dart';
import '../../../notification/presentation/notification_service.dart';
import '../../../shared/connectivity_helper.dart';

class LoginController extends ChangeNotifier {
  final IAuthRepository _repo;

  LoginController({IAuthRepository? repo}) : _repo = repo ?? AuthRepository();

  final emailController    = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;
  Map<String, String?> fieldErrors = {};

  bool _validateFields() {
    fieldErrors = {};

    if (emailController.text.trim().isEmpty) {
      fieldErrors['email'] = 'Email is required';
    } else if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(emailController.text.trim())) {
      fieldErrors['email'] = 'Enter a valid email';
    }
    if (passwordController.text.isEmpty) {
      fieldErrors['password'] = 'Password is required';
    }

    notifyListeners();
    return fieldErrors.isEmpty;
  }

  Future<void> signIn(BuildContext context) async {
    final online = await ConnectivityHelper.isOnline();
    if(!online){
      errorMessage = 'You are offline. Please try again when you\'re connected.';
      notifyListeners();
      return;
    }
  if (!_validateFields()) return;

  isLoading = true;
  errorMessage = null;
  notifyListeners();

  try {
    final response = await _repo.signIn(
      LoginRequest(
        email:    emailController.text.trim(),
        password: passwordController.text,
      ),
    );

    if (!context.mounted) return;
    // Handle case where API returns 200 but user is not verified
    if (!response.isVerified) {
      Navigator.pushNamed(
        context,
        '/verify-email',
        arguments: emailController.text.trim(),
      );
      return;
    }
    await NotificationService.saveToken(response.userId, response.accessToken);
    if (!context.mounted) return;
    await _navigate(context, response);

  } catch (e) {
  final msg = e.toString().replaceAll('Exception: ', '');

  if (msg == 'Please verify your email before signing in') {
    if (context.mounted) {
      Navigator.pushNamed(
        context,
        '/verify-email',
        arguments: emailController.text.trim(),
      );
    }
    return;
  }

  errorMessage = msg;
} finally {
    isLoading = false;
    notifyListeners();
  }
}

  Future<void> _navigate(BuildContext context, LoginResponse response) async {
    switch (response.role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, '/admin-dashboard', arguments: response.accessToken);
        break;

      case 'coach':
        Navigator.pushReplacementNamed(context, '/coach-dashboard', arguments: response.accessToken);
        break;

      case 'client':
        try {
          final profile = await _repo.getClientProfile(response.accessToken);
          if (!context.mounted) return;
          Navigator.pushReplacementNamed(
            context,
            profile.isConnected ? '/client-dashboard' : '/client-profile-only',
            arguments: response.accessToken,
          );
        } catch (_) {
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/client-dashboard', arguments: response.accessToken);
          }
        }
        break;

      default:
        errorMessage = 'Unknown role: ${response.role}';
        notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}