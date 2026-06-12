import 'package:flutter/material.dart';
import '../../data/coach_dashboard_repository.dart';
import '../../domain/coach_dashboard_model.dart';

class CoachDashboardController extends ChangeNotifier {
  final CoachDashboardRepository _repo = CoachDashboardRepository();

  CoachDashboardStatsModel? stats;
  List<CoachUpcomingClassModel> upcoming = [];
  bool isLoading    = false;
  String? errorMessage;

  Future<void> loadAll(String token) async {
    isLoading    = true;
    errorMessage = null;
    notifyListeners();

    try {
      stats    = await _repo.getStats(token);
      upcoming = await _repo.getUpcoming(token);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}