import 'package:flutter/material.dart';

class AdminProfileModel {
  final String name;
  final String email;
  final String? phone;
  final String? createdAt;
  final int totalGyms;

  AdminProfileModel({
    required this.name,
    required this.email,
    this.phone,
    this.createdAt,
    this.totalGyms = 0,
  });
}

class AdminProfileController extends ChangeNotifier {
  AdminProfileModel? profile;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  final nameController            = TextEditingController();
  final phoneController           = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController     = TextEditingController();
  final confirmPasswordController = TextEditingController();

  Future<void> loadProfile(String token) async {
    isLoading = true;
    notifyListeners();
    try {
      // TODO: replace with your actual API call
      // final data = await _repo.getAdminProfile(token);
      profile = AdminProfileModel(
        name: 'Admin Name',
        email: 'admin@example.com',
        phone: '',
        createdAt: '2024-01-01',
        totalGyms: 3,
      );
      nameController.text  = profile?.name  ?? '';
      phoneController.text = profile?.phone ?? '';
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile(String token) async {
    // Password validation
    if (newPasswordController.text.isNotEmpty) {
      if (newPasswordController.text != confirmPasswordController.text) {
        errorMessage = 'New passwords do not match';
        notifyListeners();
        return false;
      }
      if (currentPasswordController.text.isEmpty) {
        errorMessage = 'Please enter your current password';
        notifyListeners();
        return false;
      }
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      // TODO: replace with your actual API call
      // await _repo.updateAdminProfile(token, name, phone, newPassword)
      await Future.delayed(const Duration(seconds: 1)); // simulate
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}