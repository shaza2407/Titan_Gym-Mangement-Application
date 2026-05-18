import 'package:flutter/material.dart';
import '../data/gym_repository.dart';

class AdminGymController extends ChangeNotifier {
  final GymRepository _repo = GymRepository();

  List<GymModel> gyms = [];
  bool isLoading = false;
  bool isCreating = false;
  String? errorMessage;

  // create gym form controllers
  final gymNameController        = TextEditingController();
  final priceController          = TextEditingController();
  final locationController       = TextEditingController();
  final qrCodeController         = TextEditingController();
  final openingHoursController   = TextEditingController();
  final closingHoursController   = TextEditingController();

  String selectedStatus  = 'active';
  String selectedGymType = 'mixed';

  final List<String> statusOptions  = ['active', 'inactive', 'suspended'];
  final List<String> gymTypeOptions = ['males', 'females', 'mixed'];

  Future<void> loadGyms({required String token}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      gyms = await _repo.getGyms(token: token);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createGym({required String token}) async {
    isCreating = true;
    errorMessage = null;
    notifyListeners();

    try {
      final newGym = await _repo.createGym(
        token:             token,
        gymName:           gymNameController.text.trim(),
        subscriptionPrice: double.parse(priceController.text.trim()),
        location:          locationController.text.trim(),
        status:            selectedStatus,
        qrCode:            qrCodeController.text.trim(),
        gymType:           selectedGymType,
        openingHours:      openingHoursController.text.trim(),
        closingHours:      closingHoursController.text.trim(),
      );
      gyms.add(newGym); // ✅ add to list without reloading
      clearForm();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isCreating = false;
      notifyListeners();
    }
  }

  void clearForm() {
    gymNameController.clear();
    priceController.clear();
    locationController.clear();
    qrCodeController.clear();
    openingHoursController.clear();
    closingHoursController.clear();
    selectedStatus  = 'active';
    selectedGymType = 'mixed';
  }

  void setStatus(String value) {
    selectedStatus = value;
    notifyListeners();
  }

  void setGymType(String value) {
    selectedGymType = value;
    notifyListeners();
  }

  @override
  void dispose() {
    gymNameController.dispose();
    priceController.dispose();
    locationController.dispose();
    qrCodeController.dispose();
    openingHoursController.dispose();
    closingHoursController.dispose();
    super.dispose();
  }
}