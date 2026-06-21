import 'package:flutter/material.dart';
import '../../../coach/data/coach_gyms_repository.dart';
import '../../../admin/domain/schedule_model.dart';


class GymScheduleController extends ChangeNotifier {
  final GymScheduleRepository _repo = GymScheduleRepository();
  
  // Data specifically for this gym
  List<ClassSessionModel> classes = [];
  bool isLoading = true;

  Future<void> loadGymSchedule(String token, int gymId) async {
    isLoading = true;
    notifyListeners();
    try {
      // Reuse your existing repository methods
      classes = await _repo.getClasses(token, gymId); 
    } catch (e) {
      debugPrint('Error loading gym schedule: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}