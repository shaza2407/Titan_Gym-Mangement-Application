import 'package:flutter/material.dart';
import '../../data/gym_repository.dart';
import '../../domain/gym_model.dart';

class CreateGymController extends ChangeNotifier {
  final GymRepository _repo = GymRepository();

  // ── Form controllers ──────────────────────────────────────────────────────
  final gymNameController      = TextEditingController();
  final locationController     = TextEditingController();
  final openingHoursController = TextEditingController();
  final closingHoursController = TextEditingController();

  String selectedGymType = 'mixed';
  final List<String> gymTypeOptions = ['males', 'females', 'mixed'];

  // ── Machines ──────────────────────────────────────────────────────────────
  List<MachineInput> machines = [];
  final List<String> machineTypeOptions = [
    'Cardio', 'Strength', 'Flexibility', 'Balance', 'Other'
  ];

  // ── State ─────────────────────────────────────────────────────────────────
  bool isCreating = false;
  String? errorMessage;
  GymModel? createdGym;

  // ── Validation ────────────────────────────────────────────────────────────
  String? validate() {
    if (gymNameController.text.trim().isEmpty)      return 'Gym name is required.';
    if (locationController.text.trim().isEmpty)     return 'Location is required.';
    if (openingHoursController.text.trim().isEmpty) return 'Opening hours are required.';
    if (closingHoursController.text.trim().isEmpty) return 'Closing hours are required.';

    for (int i = 0; i < machines.length; i++) {
      if (machines[i].machineName.trim().isEmpty) {
        return 'Machine ${i + 1} is missing a name.';
      }
    }
    return null;
  }

  // ── Machines helpers ──────────────────────────────────────────────────────
  void addMachine() { machines.add(MachineInput()); notifyListeners(); }

  void removeMachine(int index) { machines.removeAt(index); notifyListeners(); }

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

  void setGymType(String value) {
    selectedGymType = value;
    notifyListeners();
  }

  List<Map<String, dynamic>> _getMachinesPayload() {
    return machines
        .where((m) => m.machineName.trim().isNotEmpty)
        .map((m) => {
              'machineName': m.machineName.trim(),
              'machineType': m.machineType,
              'quantity':    m.quantity,
            })
        .toList();
  }

  // ── Create gym ────────────────────────────────────────────────────────────
  Future<bool> createGym({required String token}) async {
    final validationError = validate();
    if (validationError != null) {
      errorMessage = validationError;
      notifyListeners();
      return false;
    }

    isCreating = true;
    errorMessage = null;
    notifyListeners();

    try {
      createdGym = await _repo.createGym(
        token:        token,
        gymName:      gymNameController.text.trim(),
        location:     locationController.text.trim(),
        gymType:      selectedGymType,
        openingHours: openingHoursController.text.trim(),
        closingHours: closingHoursController.text.trim(),
        machines:     _getMachinesPayload(),
      );
      _clearForm();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isCreating = false;
      notifyListeners();
    }
  }

  void _clearForm() {
    gymNameController.clear();
    locationController.clear();
    openingHoursController.clear();
    closingHoursController.clear();
    selectedGymType = 'mixed';
    machines.clear();
  }

  @override
  void dispose() {
    gymNameController.dispose();
    locationController.dispose();
    openingHoursController.dispose();
    closingHoursController.dispose();
    super.dispose();
  }
}