import 'package:flutter/material.dart';
import '../../admin/data/admin_repository.dart';

class AdminProfileController extends ChangeNotifier {
  AdminProfile? profile;
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
    errorMessage = null;
    notifyListeners();
    try {
      profile = await AdminApiService.fetchAdminProfile(token);
      nameController.text  = profile?.name  ?? '';
      phoneController.text = profile?.phone ?? '';
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile(String token) async {
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
      await AdminApiService.updateAdminProfile(
        token:           token,
        name:            nameController.text.trim(),
        phone:           phoneController.text.trim(),
        currentPassword: currentPasswordController.text.trim(),
        newPassword:     newPasswordController.text.trim(),
      );
      // refresh profile after save
      await loadProfile(token);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
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