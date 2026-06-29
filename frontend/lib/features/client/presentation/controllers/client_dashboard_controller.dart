import 'package:flutter/material.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/dashboard_model.dart';
import '../../../shared/connectivity_helper.dart';

class ClientDashboardController extends ChangeNotifier {
  final DashboardRepository _repo;
  ClientDashboardController() : _repo = DashboardRepository();
  ClientDashboardController.withRepo(this._repo);

  DashboardStatsModel? stats;
  bool isLoading = false;
  bool isOffline = false;
  String? errorMessage;

  Future<void> loadStats(String token) async {
    isLoading = true;
    errorMessage = null;
    isOffline = !(await ConnectivityHelper.isOnline());
    notifyListeners();

    try {
      stats = await _repo.getDashboardStats(token);
    } catch (e) {
      if (stats == null) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
