import 'package:flutter/material.dart';
import '../../data/gym_dashboard_repository.dart';
import '../../domain/gym_model.dart';
import '../../data/gym_repository.dart';

class GymDashboardController extends ChangeNotifier {
  final GymDashboardRepository _repo = GymDashboardRepository();

  GymDashboardStats? dashboardStats;
  bool isLoadingStats = false;
  String? statsError;

  Future<void> loadDashboardStats({
    required String token,
    required int gymId,
  }) async {
    isLoadingStats = true;
    statsError = null;
    dashboardStats = null;
    notifyListeners();
    try {
      dashboardStats = await _repo.getDashboardStats(
        token: token,
        gymId: gymId,
      );
    } catch (e) {
      statsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingStats = false;
      notifyListeners();
    }
  }

   // In gym_dashboard_controller.dart
Future<GymModel?> fetchFreshGym({
  required String token,
  required int gymId,
}) async {
  try {
    final gyms = await GymRepository().getGyms(token: token);
    return gyms.firstWhere(
      (g) => g.gymID == gymId,
      orElse: () => throw Exception('Gym not found'),
    );
  } catch (_) {
    return null;
  }
}
}