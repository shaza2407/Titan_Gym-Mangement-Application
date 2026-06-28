import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';
import '../../domain/admin_profile_model.dart';
import '../../../shared/connectivity_helper.dart';

class AdminProfileController extends ChangeNotifier {
  final AdminRepository _repo = AdminRepository();

  AdminProfile? profile;
  bool isLoading = false;
  bool isSaving  = false;
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
      profile = await _repo.fetchAdminProfile(token);
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
    final online = await ConnectivityHelper.isOnline();
    if(!online){
      errorMessage = 'You are offline. Please try again when you\'re connected.';
      notifyListeners();
      return false;
    }
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
      await _repo.updateAdminProfile(
        token:           token,
        name:            nameController.text.trim(),
        phone:           phoneController.text.trim(),
        currentPassword: currentPasswordController.text.trim(),
        newPassword:     newPasswordController.text.trim(),
      );
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