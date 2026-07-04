import 'package:flutter/material.dart';
import '../../data/gym_repository.dart';
import '../../domain/gym_model.dart';        
import 'gym_stats_controller.dart';

class AdminGymController extends ChangeNotifier {
  final GymRepository      _repo;
  final GymStatsController statsController;

  AdminGymController({GymStatsController? statsController})
      : _repo            = GymRepository(),
        statsController  = statsController ?? GymStatsController();

  // Gym list
  List<GymModel> gyms = [];
  bool isLoading = false;
  String? errorMessage;

  // Dashboard stats
  GymDashboardStats? dashboardStats;
  bool isLoadingStats = false;
  String? statsError;

  // Load gym list
  Future<void> loadGyms({required String token}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      gyms = await _repo.getGyms(token: token);
      await Future.wait([
        statsController.loadTotalMembers(token: token),
        statsController.loadAllGymStats(
          token:  token,
          gymIds: gyms.map((g) => g.gymID).toList(),
        ),
      ]);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Load dashboard stats for one gym
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
}