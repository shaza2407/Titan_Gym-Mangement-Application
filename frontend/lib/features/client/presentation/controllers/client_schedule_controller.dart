// lib/features/client/presentation/controllers/client_schedule_controller.dart

import 'package:flutter/material.dart';
import '../../data/schedule_repository.dart';
import '../../domain/schedule_model.dart';

class ClientScheduleController extends ChangeNotifier {
  final ScheduleRepository _repo = ScheduleRepository();

  ScheduleStatsModel? stats;
  List<ClassModel> myClasses = [];
  List<ClassModel> browseClasses = [];
  List<WeeklyDayModel> weekly = [];

  bool isLoading = false;
  bool isBrowseLoading = false;
  String? errorMessage;

  int selectedTab = 0;
  String? selectedDay;

  final List<String> days = [
    'All',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  Future<void> loadAll(String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final results = await Future.wait([
      _safe(() async => stats = await _repo.getStats(token)),
      _safe(() async => myClasses = await _repo.getMyClasses(token)),
      _safe(() async => browseClasses = await _repo.browseClasses(token)),
      _safe(() async => weekly = await _repo.getWeekly(token)),
    ]);

    final allFailed = results.every((ok) => ok == false);
    final nothingToShow = stats == null && myClasses.isEmpty && weekly.isEmpty;
    if (allFailed && nothingToShow) {
      errorMessage =
          'Unable to load your schedule. Check your connection and try again.';
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

  Future<void> filterByDay(String token, String? day) async {
    selectedDay = day;
    isBrowseLoading = true;
    notifyListeners();

    try {
      browseClasses = await _repo.browseClasses(
        token,
        day: day == 'All' || day == null ? null : day,
      );
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isBrowseLoading = false;
      notifyListeners();
    }
  }

  Future<bool> enroll(String token, int sessionId, String classDate) async {
    try {
      await _repo.enroll(token, sessionId, classDate);
      await loadAll(token);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> unenroll(String token, int sessionId, String classDate) async {
    try {
      await _repo.unenroll(token, sessionId, classDate);
      await loadAll(token);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void setTab(int index) {
    selectedTab = index;
    notifyListeners();
  }
}
