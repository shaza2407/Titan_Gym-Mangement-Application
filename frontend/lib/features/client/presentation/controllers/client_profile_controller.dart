import 'package:flutter/material.dart';
import '../../data/client_repository.dart';
import '../../domain/client_profile_model.dart';

class ClientProfileController extends ChangeNotifier {
  final ClientRepository _repo = ClientRepository();

  ClientProfileModel? profile;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  // Controllers for editable fields
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();
  final bioController = TextEditingController();
  final emergencyContactController = TextEditingController();

  String? selectedGender;
  String? selectedFitnessGoal;

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
    errorMessage = null;
    notifyListeners();

    try {
      profile = await _repo.getProfile(token);
      // Fill controllers with existing data
      nameController.text = profile!.name;
      phoneController.text = profile!.phone ?? '';
      ageController.text = profile!.age?.toString() ?? '';
      bioController.text = profile!.bio ?? '';
      emergencyContactController.text = profile!.emergencyContact ?? '';
      selectedGender = profile!.gender;
      selectedFitnessGoal = fitnessGoals.contains(profile!.fitnessGoal)
          ? profile!.fitnessGoal
          : null;
    } catch (e) {
      errorMessage = e.toString();
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
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'age': int.tryParse(ageController.text.trim()),
        'bio': bioController.text.trim(),
        'emergency_contact': emergencyContactController.text.trim(),
        'gender': selectedGender,
        'fitness_goal': selectedFitnessGoal,
      });
      return true;
    } catch (e) {
      errorMessage = e.toString();
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
}
