import 'package:flutter/material.dart';
import '../data/auth_repository.dart';

class VerifyEmailController extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  final codeController = TextEditingController();

  bool isLoading = false;
  bool isResending = false;
  String? errorMessage;
  String? successMessage;

  Future<void> verifyEmail(BuildContext context, String email) async {
    if (codeController.text.trim().isEmpty) {
      errorMessage = 'Please enter the verification code';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      await _repo.verifyEmail(
        email: email,
        code: codeController.text.trim(),
      );
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resendVerification(String email) async {
    isResending = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      await _repo.resendVerification(email: email);
      successMessage = 'Verification code resent successfully';
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isResending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }
}