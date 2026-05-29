// lib/features/client/presentation/controllers/client_schedule_controller.dart

import 'package:flutter/material.dart';
import '../../data/schedule_repository.dart';
import '../../domain/schedule_model.dart';

class ClientScheduleController extends ChangeNotifier {
  final ScheduleRepository _repo = ScheduleRepository();

  ScheduleStatsModel? stats;
  List<ClassModel> myClasses    = [];
  List<ClassModel> browseClasses = [];
  List<WeeklyDayModel> weekly   = [];

  bool isLoading       = false;
  bool isBrowseLoading = false;
  String? errorMessage;

  int selectedTab  = 0;  // 0=MyClasses, 1=Browse
  String? selectedDay;

  final List<String> days = [
    'All', 'monday', 'tuesday', 'wednesday',
    'thursday', 'friday', 'saturday', 'sunday',
  ];

  Future<void> loadAll(String token) async {
    isLoading    = true;
    errorMessage = null;
    notifyListeners();

    try {
      stats         = await _repo.getStats(token);
      myClasses     = await _repo.getMyClasses(token);
      browseClasses = await _repo.browseClasses(token);
      weekly        = await _repo.getWeekly(token);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filterByDay(String token, String? day) async {
    selectedDay     = day;
    isBrowseLoading = true;
    notifyListeners();

    try {
      browseClasses = await _repo.browseClasses(
        token,
        day: day == 'All' || day == null ? null : day,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isBrowseLoading = false;
      notifyListeners();
    }
  }

  Future<bool> enroll(String token, int sessionId) async {
    try {
      await _repo.enroll(token, sessionId);
      await loadAll(token);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> unenroll(String token, int sessionId) async {
    try {
      await _repo.unenroll(token, sessionId);
      await loadAll(token);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setTab(int index) {
    selectedTab = index;
    notifyListeners();
  }
}