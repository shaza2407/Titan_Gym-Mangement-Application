import 'package:flutter/material.dart';
import '../../data/coach_profile_repository.dart';
import '../../domain/coach_profile_model.dart';

class CoachProfileController extends ChangeNotifier {
  final CoachProfileRepository _repo = CoachProfileRepository();

  CoachProfileModel? profile;
  List<String> availableSpecializations = [];
  List<String> selectedSpecializations = [];

  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  final certificationsController = TextEditingController();
  final yearsExperienceController = TextEditingController();
  String? dateOfBirth;

  Future<void> loadProfile(String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    bool profileOk = true;
    try {
      profile = await _repo.getProfile(token);
      nameController.text = profile!.name;
      phoneController.text = profile!.phone ?? '';
      bioController.text = profile!.bio ?? '';
      certificationsController.text = profile!.certifications ?? '';
      yearsExperienceController.text =
          profile!.yearsExperience?.toString() ?? '';
      dateOfBirth = profile!.dateOfBirth;
      selectedSpecializations = profile!.specializations ?? [];
    } catch (e) {
      profileOk = false;
    }

    try {
      availableSpecializations = await _repo.getSpecializations(token);
    } catch (e) {
      // non-fatal — specialization selector will just be empty/unavailable
    }

    if (!profileOk && profile == null) {
      errorMessage =
          'Unable to load your profile. Check your connection and try again.';
    }

    isLoading = false;
    notifyListeners();
  }

  void toggleSpecialization(String spec) {
    if (selectedSpecializations.contains(spec)) {
      selectedSpecializations = selectedSpecializations
          .where((s) => s != spec)
          .toList();
    } else {
      selectedSpecializations = [...selectedSpecializations, spec];
    }
    notifyListeners();
  }

  Future<bool> saveProfile(String token) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      String? phone = phoneController.text.trim().isEmpty
          ? null
          : phoneController.text.trim();

      profile = await _repo.updateProfile(token, {
        'name': nameController.text.trim().isEmpty
            ? null
            : nameController.text.trim(),
        'phone': phone,
        'bio': bioController.text.trim().isEmpty
            ? null
            : bioController.text.trim(),
        'specializations': selectedSpecializations.isEmpty
            ? null
            : selectedSpecializations,
        'certifications': certificationsController.text.trim().isEmpty
            ? null
            : certificationsController.text.trim(),
        'years_experience': int.tryParse(yearsExperienceController.text.trim()),
        'date_of_birth': dateOfBirth,
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

  void setDateOfBirth(String? value) {
    dateOfBirth = value;
    notifyListeners();
  }
}
