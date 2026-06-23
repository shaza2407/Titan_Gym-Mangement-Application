// lib/features/client/presentation/controllers/client_profile_controller.dart

import 'package:flutter/material.dart';
import '../../data/client_repository.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/client_profile_model.dart';
import '../../domain/dashboard_model.dart';

class ClientProfileController extends ChangeNotifier {
  final ClientRepository _repo = ClientRepository();
  final DashboardRepository _dashRepo = DashboardRepository();

  ClientProfileModel? profile;
  DashboardStatsModel? dashboardStats;
  bool isLoading = false;
  bool isSaving  = false;
  String? errorMessage;

  final nameController             = TextEditingController();
  final phoneController            = TextEditingController();
  final bioController              = TextEditingController();
  final emergencyContactController = TextEditingController();

  String? selectedGender;
  String? selectedFitnessGoal;
  String? dateOfBirth;  // ← replaces ageController

  final List<String> genders      = ['male', 'female', 'other'];
  final List<String> fitnessGoals = [
    'weight_loss', 'muscle_gain', 'endurance',
    'flexibility', 'general_fitness', 'long_dist_running'
  ];

  Future<void> loadProfile(String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repo.getProfile(token),
        _dashRepo.getDashboardStats(token),
      ]);
      profile = results[0] as ClientProfileModel;
      dashboardStats = results[1] as DashboardStatsModel;
      nameController.text             = profile!.name;
      phoneController.text            = profile!.phone ?? '';
      bioController.text              = profile!.bio ?? '';
      emergencyContactController.text = profile!.emergencyContact ?? '';
      selectedGender                  = profile!.gender;
      selectedFitnessGoal             = fitnessGoals.contains(profile!.fitnessGoal)
          ? profile!.fitnessGoal
          : null;
      dateOfBirth                     = profile!.dateOfBirth;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile(String token) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      profile = await _repo.updateProfile(token, {
        'name':              nameController.text.trim(),
        'phone':             phoneController.text.trim(),
        'bio':               bioController.text.trim(),
        'emergency_contact': emergencyContactController.text.trim(),
        'gender':            selectedGender,
        'fitness_goal':      selectedFitnessGoal,
        'date_of_birth':     dateOfBirth,
      });
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void setGender(String? value) {
    selectedGender = value;
    notifyListeners();
  }

  void setFitnessGoal(String? value) {
    selectedFitnessGoal = value;
    notifyListeners();
  }

  void setDateOfBirth(String? value) {
    dateOfBirth = value;
    notifyListeners();
  }
}