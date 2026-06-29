import 'package:flutter/material.dart';
import '../../domain/auth_model.dart';
import '../../domain/i_auth_repository.dart';
import '../../data/auth_repository.dart';
import '../../../shared/connectivity_helper.dart';

class SignupController extends ChangeNotifier {
  final IAuthRepository _repo;

  SignupController({IAuthRepository? repo}) : _repo = repo ?? AuthRepository();

  final fullNameController = TextEditingController();
  final emailController    = TextEditingController();
  final phoneController    = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController  = TextEditingController();

  String? selectedRole;
  bool isLoading = false;
  String? errorMessage;
  Map<String, String?> fieldErrors = {};

  final List<String> roles = ['client', 'coach', 'admin'];

  void setRole(String? role) {
    if (role == null) return;
    selectedRole = role;
    fieldErrors.remove('role');
    notifyListeners();
  }

  bool _validateFields() {
    fieldErrors = {};

    if (fullNameController.text.trim().isEmpty) {
      fieldErrors['fullName'] = 'Full name is required';
    }

    if (emailController.text.trim().isEmpty) {
      fieldErrors['email'] = 'Email is required';
    } else if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(emailController.text.trim())) {
      fieldErrors['email'] = 'Enter a valid email';
    }

    if (phoneController.text.trim().isEmpty) {
      fieldErrors['phone'] = 'Phone number is required';
    } else if (!RegExp(r'^\+?[0-9]{11}$')
        .hasMatch(phoneController.text.trim())) {
      fieldErrors['phone'] = 'Enter a valid phone number';
    }

    if (selectedRole == null) {
      fieldErrors['role'] = 'Please select a role';
    }

    if (passwordController.text.isEmpty) {
      fieldErrors['password'] = 'Password is required';
    } else if (passwordController.text.length < 6) {
      fieldErrors['password'] = 'Password must be at least 6 characters';
    }

    if (confirmController.text.isEmpty) {
      fieldErrors['confirm'] = 'Please confirm your password';
    } else if (passwordController.text != confirmController.text) {
      fieldErrors['confirm'] = 'Passwords do not match';
    }

    notifyListeners();
    return fieldErrors.isEmpty;
  }

  Future<void> signUp(BuildContext context) async {
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
      await _repo.signUp(
        SignUpRequest(
          fullName:    fullNameController.text.trim(),
          email:       emailController.text.trim(),
          phoneNumber: phoneController.text.trim(),
          password:    passwordController.text,
          role:        selectedRole!,
        ),
      );

      if (context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/verify-email',
          arguments: emailController.text.trim(),
        );
      }
    } catch (e) {
      errorMessage = e.toString().replaceAll('Error: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }
}