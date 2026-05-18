import 'package:flutter/material.dart';
import '../data/auth_repository.dart';

class ForgotPasswordController extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  final emailController    = TextEditingController();
  final codeController     = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController  = TextEditingController();

  bool isLoading    = false;
  bool codeSent     = false;  // controls which step to show
  String? errorMessage;
  String? successMessage;
  String? sentEmail; // store email to pass to reset step

  // Step 1 — send code to email
  Future<void> sendCode() async {
    if (emailController.text.trim().isEmpty) {
      errorMessage = 'Please enter your email';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repo.forgotPassword(email: emailController.text.trim());
      sentEmail = emailController.text.trim();
      codeSent = true;  // ✅ show code + new password fields
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Step 2 — verify code and reset password
  Future<void> resetPassword(BuildContext context) async {
    if (passwordController.text != confirmController.text) {
      errorMessage = 'Passwords do not match';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repo.resetPassword(
        email:       sentEmail!,
        code:        codeController.text.trim(),
        newPassword: passwordController.text,
      );
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }
}