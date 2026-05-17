import 'package:flutter/material.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/dashboard_model.dart';

class ClientDashboardController extends ChangeNotifier {
  final DashboardRepository _repo = DashboardRepository();

  DashboardStatsModel? stats;
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadStats(String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      stats = await _repo.getDashboardStats(token);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}