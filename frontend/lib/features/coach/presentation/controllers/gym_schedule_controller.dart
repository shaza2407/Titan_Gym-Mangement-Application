import 'package:flutter/material.dart';
import '../../../coach/data/coach_gyms_repository.dart';
import '../../../admin/domain/schedule_model.dart';

class GymScheduleController extends ChangeNotifier {
  final GymScheduleRepository _repo = GymScheduleRepository();

  List<ClassSessionModel> classes = [];
  bool isLoading = true;
  String? errorMessage;

  Future<void> loadGymSchedule(String token, int gymId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final today = DateTime.now();
      final monday = today.subtract(Duration(days: today.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));

      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      classes = await _repo.getClasses(
        token,
        gymId,
        weekStart: fmt(monday),
        weekEnd: fmt(sunday),
      );
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
