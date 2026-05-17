import 'package:flutter/material.dart';
import '../data/auth_repository.dart';

class SignupController extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  final fullNameController = TextEditingController();
  final emailController    = TextEditingController();
  final phoneController    = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController  = TextEditingController();

  String? selectedRole;
  bool isLoading = false;
  String? errorMessage;

  final List<String> roles = ['client', 'coach', 'admin'];

  void setRole(String? role) {
    if (role == null) return;
    selectedRole = role;
    notifyListeners();
}

  Future<void> signUp(BuildContext context) async {
    if (passwordController.text != confirmController.text) {
      errorMessage = 'Passwords do not match';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();


    try {
      await _repo.signUp(
        fullName:    fullNameController.text.trim(),
        email:       emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        password:    passwordController.text,
        role:        selectedRole!,
      
      );

    Navigator.pushReplacementNamed(context,'/verify-email',arguments: emailController.text.trim(),);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}