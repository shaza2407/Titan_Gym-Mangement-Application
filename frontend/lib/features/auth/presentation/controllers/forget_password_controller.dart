import 'package:flutter/material.dart';
import '../../data/auth_repository.dart';
import '../../domain/i_auth_repository.dart';
import '../../domain/auth_model.dart'; 
import '../../../shared/connectivity_helper.dart';

class ForgotPasswordController extends ChangeNotifier {
  final IAuthRepository _repo;

  ForgotPasswordController({IAuthRepository? repo}) : _repo = repo ?? AuthRepository();

  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isLoading = false;
  bool codeSent = false; // controls which step to show
  String? errorMessage;
  String? successMessage;
  String? sentEmail; // store email to pass to reset step

  // Step 1 — send code to email
  Future<void> sendCode() async {
    final online = await ConnectivityHelper.isOnline();
    if(!online){
      errorMessage = 'You are offline. Please try again when you\'re connected.';
      notifyListeners();
      return;
    }
    if (emailController.text.trim().isEmpty) {
      errorMessage = 'Please enter your email';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
    await _repo.forgotPassword(ForgotPasswordRequest(email: emailController.text.trim()));
      sentEmail = emailController.text.trim();
      codeSent = true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Step 2 — verify code and reset password
  // Returns true on success so the UI can show a confirmation dialog
  // and decide where to navigate next.
  Future<bool> resetPassword() async {
    final online = await ConnectivityHelper.isOnline();
    if(!online){
      errorMessage = 'You are offline. Please try again when you\'re connected.';
      notifyListeners();
      return false;
    }
    if (passwordController.text != confirmController.text) {
      errorMessage = 'Passwords do not match';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repo.resetPassword(ResetPasswordRequest(
        email: sentEmail!,
        code: codeController.text.trim(),
        newPassword: passwordController.text,
    ));
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
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
