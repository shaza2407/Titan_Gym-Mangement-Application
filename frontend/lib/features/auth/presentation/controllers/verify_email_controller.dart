import 'package:flutter/material.dart';
import '../../data/auth_repository.dart';
import '../../domain/i_auth_repository.dart';
import '../../domain/auth_model.dart';
import '../../../shared/connectivity_helper.dart';

class VerifyEmailController extends ChangeNotifier {
  final IAuthRepository _repo;

  VerifyEmailController({IAuthRepository? repo})
      : _repo = repo ?? AuthRepository();

  final codeController = TextEditingController();

  bool isLoading = false;
  bool isResending = false;
  String? errorMessage;
  String? successMessage;

  Future<void> verifyEmail(BuildContext context, String email) async {
    final online = await ConnectivityHelper.isOnline();
    if(!online){
      errorMessage = 'You are offline. Please try again when you\'re connected.';
      notifyListeners();
      return;
    }
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
        VerifyEmailRequest(
          email: email,
          code: codeController.text.trim(),
        ),
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
    final online = await ConnectivityHelper.isOnline();
    if(!online){
      errorMessage = 'You are offline. Please try again when you\'re connected.';
      notifyListeners();
      return;
    }
    isResending = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      await _repo.resendVerification(email);
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