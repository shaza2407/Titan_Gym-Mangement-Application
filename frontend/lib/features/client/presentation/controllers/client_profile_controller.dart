import 'package:flutter/material.dart';
import '../../data/client_repository.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/client_profile_model.dart';
import '../../domain/dashboard_model.dart';
import '../../../shared/connectivity_helper.dart';

class ClientProfileController extends ChangeNotifier {
  final ClientRepository _repo = ClientRepository();
  final DashboardRepository _dashRepo = DashboardRepository();

  ClientProfileModel? profile;
  DashboardStatsModel? dashboardStats;
  bool isLoading = false;
  bool isSaving = false;
  bool isOffline = false; // true when showing cached data
  String? errorMessage;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  final emergencyContactController = TextEditingController();

  String? selectedGender;
  String? selectedFitnessGoal;
  String? dateOfBirth;

  final List<String> genders = ['male', 'female', 'other'];
  final List<String> fitnessGoals = [
    'weight_loss',
    'muscle_gain',
    'endurance',
    'flexibility',
    'general_fitness',
    'long_dist_running',
  ];

  Future<void> loadProfile(String token) async {
    isLoading = true;
    isOffline = !(await ConnectivityHelper.isOnline());
    errorMessage = null;
    notifyListeners();

    try {
      // Both repos now cache — safe to run in parallel even offline
      final results = await Future.wait([
        _repo.getProfile(token),
        _dashRepo.getDashboardStats(token),
      ]);
      profile = results[0] as ClientProfileModel;
      dashboardStats = results[1] as DashboardStatsModel;

      nameController.text = profile!.name;
      phoneController.text = profile!.phone ?? '';
      bioController.text = profile!.bio ?? '';
      emergencyContactController.text = profile!.emergencyContact ?? '';
      selectedGender = profile!.gender;
      selectedFitnessGoal = fitnessGoals.contains(profile!.fitnessGoal)
          ? profile!.fitnessGoal
          : null;
      dateOfBirth = profile!.dateOfBirth;
    } catch (e) {
      // Only show error if we have nothing to show at all
      if (profile == null) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      // If profile loaded but dashboardStats failed (or vice versa),
      // stay silent — partial data is better than an error screen
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
      // Repo throws a clear offline message — no need to duplicate the check here
      profile = await _repo.updateProfile(token, {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'bio': bioController.text.trim(),
        'emergency_contact': emergencyContactController.text.trim(),
        'gender': selectedGender,
        'fitness_goal': selectedFitnessGoal,
        'date_of_birth': dateOfBirth,
      });
      isOffline = false; // successful save means we're back online
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

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    bioController.dispose();
    emergencyContactController.dispose();
    super.dispose();
  }
}
