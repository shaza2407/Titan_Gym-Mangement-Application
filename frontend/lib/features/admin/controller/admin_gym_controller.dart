import 'package:flutter/material.dart';
import '../data/gym_repository.dart';

class AdminGymController extends ChangeNotifier {
  final GymRepository _repo = GymRepository();

  // ── Gym list ──────────────────────────────────────────────────────────────
  List<GymModel> gyms = [];
  bool isLoading = false;
  String? errorMessage;

  // ── Dashboard stats ───────────────────────────────────────────────────────
  GymDashboardStats? dashboardStats;
  bool isLoadingStats = false;
  String? statsError;

  // ── Create gym form ───────────────────────────────────────────────────────
  bool isCreating = false;
  final gymNameController      = TextEditingController();
  final priceController        = TextEditingController();
  final yearlyPriceController  = TextEditingController();
  final locationController     = TextEditingController();
  final openingHoursController = TextEditingController();
  final closingHoursController = TextEditingController();
  String selectedGymType = 'mixed';
  final List<String> gymTypeOptions = ['males', 'females', 'mixed'];

  // ── Load gym list ─────────────────────────────────────────────────────────
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

  // ── Load dashboard stats for one gym ─────────────────────────────────────
  Future<void> loadDashboardStats({
    required String token,
    required int gymId,
  }) async {
    isLoadingStats = true;
    statsError = null;
    dashboardStats = null;
    notifyListeners();
    try {
      dashboardStats = await _repo.getDashboardStats(token: token, gymId: gymId);
    } catch (e) {
      statsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingStats = false;
      notifyListeners();
    }
  }

  // ── Create gym ────────────────────────────────────────────────────────────
  Future<void> createGym({required String token}) async {
    isCreating = true;
    errorMessage = null;
    notifyListeners();
    try {
      final newGym = await _repo.createGym(
        token:             token,
        gymName:           gymNameController.text.trim(),
        subscriptionPrice: double.parse(priceController.text.trim()),
        yearlySubscriptionPrice:     double.parse(yearlyPriceController.text.trim()),
        location:          locationController.text.trim(),
        gymType:           selectedGymType,
        openingHours:      openingHoursController.text.trim(),
        closingHours:      closingHoursController.text.trim(),
      );
      gyms.add(newGym);
      clearForm();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isCreating = false;
      notifyListeners();
    }
  }

  void setGymType(String value) {
    selectedGymType = value;
    notifyListeners();
  }

  void clearForm() {
    gymNameController.clear();
    priceController.clear();
    yearlyPriceController.clear();
    locationController.clear();
    openingHoursController.clear();
    closingHoursController.clear();
    selectedGymType = 'mixed';
  }

  @override
  void dispose() {
    gymNameController.dispose();
    priceController.dispose();
    yearlyPriceController.dispose();
    locationController.dispose();
    openingHoursController.dispose();
    closingHoursController.dispose();
    super.dispose();
  }
}