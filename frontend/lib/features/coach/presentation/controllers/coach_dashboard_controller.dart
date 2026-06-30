import 'package:flutter/material.dart';
import '../../data/coach_dashboard_repository.dart';
import '../../domain/coach_dashboard_model.dart';

class CoachDashboardController extends ChangeNotifier {
  final CoachDashboardRepository _repo = CoachDashboardRepository();

  CoachDashboardStatsModel? stats;
  List<CoachUpcomingClassModel> upcoming = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadAll(String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final results = await Future.wait([
      _safe(() async => stats = await _repo.getStats(token)),
      _safe(() async => upcoming = await _repo.getUpcoming(token)),
    ]);

    final allFailed = results.every((ok) => ok == false);
    if (allFailed && stats == null && upcoming.isEmpty) {
      errorMessage =
          'Unable to load your dashboard. Check your connection and try again.';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> _safe(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (_) {
      return false;
    }
  }
}
