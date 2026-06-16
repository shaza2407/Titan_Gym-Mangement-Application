import 'package:flutter/material.dart';
import '../../data/coach_profile_repository.dart';
import '../../domain/coach_profile_model.dart';

class CoachProfileController extends ChangeNotifier {
  final CoachProfileRepository _repo = CoachProfileRepository();

  CoachProfileModel? profile;
  List<String> availableSpecializations = [];
  List<String> selectedSpecializations  = [];

  bool isLoading = false;
  bool isSaving  = false;
  String? errorMessage;

  final nameController            = TextEditingController();
  final phoneController           = TextEditingController();
  final bioController             = TextEditingController();
  final certificationsController  = TextEditingController();
  final yearsExperienceController = TextEditingController();
  String? dateOfBirth;

  Future<void> loadProfile(String token) async {
    isLoading    = true;
    errorMessage = null;
    notifyListeners();

    try {
      profile                  = await _repo.getProfile(token);
      availableSpecializations = await _repo.getSpecializations(token);

      nameController.text            = profile!.name;
      phoneController.text           = profile!.phone ?? '';
      bioController.text             = profile!.bio ?? '';
      certificationsController.text  = profile!.certifications ?? '';
      yearsExperienceController.text = profile!.yearsExperience?.toString() ?? '';
      dateOfBirth                    = profile!.dateOfBirth;
      selectedSpecializations        = profile!.specializations ?? [];
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void toggleSpecialization(String spec) {
    if (selectedSpecializations.contains(spec)) {
      selectedSpecializations =
          selectedSpecializations.where((s) => s != spec).toList();
    } else {
      selectedSpecializations = [...selectedSpecializations, spec];
    }
    notifyListeners();
  }

  Future<bool> saveProfile(String token) async {
    isSaving     = true;
    errorMessage = null;
    notifyListeners();

    try {
      profile = await _repo.updateProfile(token, {
        'name':             nameController.text.trim(),
        'phone':            phoneController.text.trim(),
        'bio':              bioController.text.trim(),
        'specializations':  selectedSpecializations,
        'certifications':   certificationsController.text.trim(),
        'years_experience': int.tryParse(yearsExperienceController.text.trim()),
        'date_of_birth':    dateOfBirth,
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

  void setDateOfBirth(String? value) {
    dateOfBirth = value;
    notifyListeners();
  }
}