import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';
import '../../domain/gym_model.dart';

class GymSettingsController extends ChangeNotifier {
  final GymModel gym;
  final String token;

  // ── Form controllers ──────────────────────────────────────────────────────
  late final TextEditingController gymNameCtrl;
  late final TextEditingController gymTypeCtrl;
  late final TextEditingController locationCtrl;
  late final TextEditingController openingCtrl;
  late final TextEditingController closingCtrl;

  // ── Machines ──────────────────────────────────────────────────────────────
  List<MachineInput> machines = [];
  final List<String> machineTypeOptions = [
    'Cardio', 'Strength', 'Flexibility', 'Balance', 'Other'
  ];

  // ── State ─────────────────────────────────────────────────────────────────
  bool isLoading = false;
  bool isSaved = false;
  String? errorMessage;
  String selectedGymType;

  GymSettingsController({required this.gym, required this.token})
      : selectedGymType = gym.gymType {
    gymNameCtrl  = TextEditingController(text: gym.gymName);
    gymTypeCtrl  = TextEditingController(text: gym.gymType);
    locationCtrl = TextEditingController(text: gym.location);
    openingCtrl  = TextEditingController(text: gym.openingHours);
    closingCtrl  = TextEditingController(text: gym.closingHours);

    //load existing machines from gym model
    machines = gym.machines.map((m) => MachineInput(
      machineName: m.machineName,
      machineType: m.machineType,
      quantity:    m.quantity,
    )).toList();
  }

  // ── Gym type ──────────────────────────────────────────────────────────────
  void setGymType(String value) {
    selectedGymType = value;
    gymTypeCtrl.text = value;
    notifyListeners();
  }

  // ── Machine helpers ───────────────────────────────────────────────────────
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
        .where((m) => m.machineName.trim().isNotEmpty)
        .map((m) => {
              'machineName': m.machineName.trim(),
              'machineType': m.machineType,
              'quantity':    m.quantity,
            })
        .toList();
  }

  // ── Validation ────────────────────────────────────────────────────────────
  String? validate() {
    if (gymNameCtrl.text.trim().isEmpty)  return 'Gym name is required.';
    if (locationCtrl.text.trim().isEmpty) return 'Location is required.';
    if (openingCtrl.text.trim().isEmpty)  return 'Opening hours are required.';
    if (closingCtrl.text.trim().isEmpty)  return 'Closing hours are required.';
    for (int i = 0; i < machines.length; i++) {
      if (machines[i].machineName.trim().isEmpty) {
        return 'Machine ${i + 1} is missing a name.';
      }
    }
    return null;
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<bool> save() async {
    final error = validate();
    if (error != null) {
      errorMessage = error;
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    isSaved = false;
    notifyListeners();

    try {
      await AdminApiService.updateGym(
        gymId:        gym.gymID,
        token:        token,
        gymName:      gymNameCtrl.text.trim(),
        gymType:      selectedGymType,
        location:     locationCtrl.text.trim(),
        openingHours: openingCtrl.text.trim(),
        closingHours: closingCtrl.text.trim(),
        machines:     _getMachinesPayload(), 
      );
      isSaved = true;
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    gymNameCtrl.dispose();
    gymTypeCtrl.dispose();
    locationCtrl.dispose();
    openingCtrl.dispose();
    closingCtrl.dispose();
    super.dispose();
  }
}