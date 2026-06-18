import 'package:flutter/material.dart';
import '../data/gym_repository.dart';

// ── Machine input model ───────────────────────────────────────────────────────
class MachineInput {
  String machineName;
  String machineType;
  int quantity;

  MachineInput({
    this.machineName = '',
    this.machineType = 'Cardio',
    this.quantity = 1,
  });
}

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

  // ── Machines ──────────────────────────────────────────────────────────────
  List<MachineInput> machines = [];
  final List<String> machineTypeOptions = ['Cardio', 'Strength', 'Flexibility', 'Balance', 'Other'];

  void addMachine() {
    machines.add(MachineInput());
    notifyListeners();
  }

  void removeMachine(int index) {
    machines.removeAt(index);
    notifyListeners();
  }

  void updateMachineName(int index, String value) {
    machines[index].machineName = value;
  }

  void updateMachineType(int index, String value) {
    machines[index].machineType = value;
    notifyListeners();
  }

  void updateMachineQuantity(int index, int value) {
    machines[index].quantity = value;
    notifyListeners();
  }

  List<Map<String, dynamic>> _getMachinesPayload() {
    return machines
        .where((m) => m.machineName.trim().isNotEmpty) // skip empty ones
        .map((m) => {
              'machineName': m.machineName.trim(),
              'machineType': m.machineType,
              'quantity': m.quantity,
              'status': 'available',
            })
        .toList();
  }

  // ── Load gym list ─────────────────────────────────────────────────────────
  Future<void> loadGyms({required String token}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      gyms = await _repo.getGyms(token: token);
      await loadTotalMembers(token: token);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Load dashboard stats for one gym ─────────────────────────────────────
  Future<void> loadDashboardStats({required String token, required int gymId}) async {
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

  // ── Total members ─────────────────────────────────────────────────────────
  int totalMembers = 0;
  bool isLoadingTotalMembers = false;

  Future<void> loadTotalMembers({required String token}) async {
    isLoadingTotalMembers = true;
    notifyListeners();
    try {
      totalMembers = await _repo.getTotalMembers(token: token);
    } catch (e) {
      totalMembers = 0;
    } finally {
      isLoadingTotalMembers = false;
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
        token:                  token,
        gymName:                gymNameController.text.trim(),
        subscriptionPrice:      double.parse(priceController.text.trim()),
        yearlySubscriptionPrice: double.parse(yearlyPriceController.text.trim()),
        location:               locationController.text.trim(),
        gymType:                selectedGymType,
        openingHours:           openingHoursController.text.trim(),
        closingHours:           closingHoursController.text.trim(),
        machines:               _getMachinesPayload(), // ← added
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
    machines.clear(); // ← clear machines too
    notifyListeners();
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