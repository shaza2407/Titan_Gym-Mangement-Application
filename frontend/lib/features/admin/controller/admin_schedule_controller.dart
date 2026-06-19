// lib/features/admin/presentation/controllers/admin_schedule_controller.dart

import 'package:flutter/material.dart';
import '../data/admin_schedule_repository.dart';
import '../domain/schedule_model.dart';

class AdminScheduleController extends ChangeNotifier {
  final AdminScheduleRepository _repo = AdminScheduleRepository();

  bool isLoading = true;
  bool isMutating = false;
  String? errorMessage;

  int selectedTab = 0; // 0 = Schedule, 1 = Table, 2 = Requests
  String selectedDay = 'All';

  AdminScheduleStatsModel? stats;
  List<ClassSessionModel> classes = [];
  List<ClassRequestModel> requests = [];
  List<CoachOptionModel> coaches = [];

  static const days = [
    'All', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  ];

  Future<void> loadAll(String token, int gymId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repo.getStats(token, gymId),
        _repo.getClasses(token, gymId),
        _repo.getPendingRequests(token, gymId),
        _repo.getCoaches(token, gymId),
      ]);
      stats    = results[0] as AdminScheduleStatsModel;
      classes  = results[1] as List<ClassSessionModel>;
      requests = results[2] as List<ClassRequestModel>;
      coaches  = results[3] as List<CoachOptionModel>;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setTab(int index) {
    selectedTab = index;
    notifyListeners();
  }

  void setDayFilter(String day) {
    selectedDay = day;
    notifyListeners();
  }

  List<ClassSessionModel> get filteredClasses {
    if (selectedDay == 'All') return classes;
    return classes.where((c) => c.dayOfWeek == selectedDay).toList();
  }

  Map<String, List<ClassSessionModel>> get weeklySchedule {
    final map = <String, List<ClassSessionModel>>{};
    for (final day in days.skip(1)) {
      map[day] = classes.where((c) => c.dayOfWeek == day).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return map;
  }

  Color capacityColor(ClassSessionModel c) {
    if (c.isFull) return Colors.red;
    if (c.fillRatio > 0.8) return Colors.orange;
    return const Color(0xFF4CAF50);
  }

  Future<bool> createClass(String token, int gymId, Map<String, dynamic> payload) async {
    isMutating = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.createClass(token, gymId, payload);
      await loadAll(token, gymId);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      isMutating = false;
    }
  }

  Future<bool> editClass(
    String token,
    int gymId,
    int sessionId,
    Map<String, dynamic> payload,
  ) async {
    isMutating = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.editClass(token, gymId, sessionId, payload);
      await loadAll(token, gymId);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      isMutating = false;
    }
  }

  Future<bool> deleteClass(String token, int gymId, int sessionId) async {
    try {
      await _repo.deleteClass(token, gymId, sessionId);
      await loadAll(token, gymId);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<List<ClassMemberModel>> getClassMembers(
    String token,
    int gymId,
    int sessionId, {
    String? classDate,
  }) {
    return _repo.getClassMembers(token, gymId, sessionId, classDate: classDate);
  }

  Future<bool> approveRequest(String token, int gymId, int requestId) async {
    try {
      await _repo.approveRequest(token, gymId, requestId);
      await loadAll(token, gymId);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectRequest(String token, int gymId, int requestId) async {
    try {
      await _repo.rejectRequest(token, gymId, requestId);
      await loadAll(token, gymId);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}