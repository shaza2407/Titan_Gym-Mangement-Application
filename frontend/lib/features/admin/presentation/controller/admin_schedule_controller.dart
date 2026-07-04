import 'package:flutter/material.dart';
import '../../data/admin_schedule_repository.dart';
import '../../domain/schedule_model.dart';
import '../../../shared/connectivity_helper.dart';

class AdminScheduleController extends ChangeNotifier {
  final AdminScheduleRepository _repo = AdminScheduleRepository();

  bool isLoading = true;
  bool isMutating = false;
  String? errorMessage;

  int selectedTab = 0; // 0 = Schedule, 1 = Table, 2 = Requests
  String selectedDay = 'All';

  List<ClassRequestModel> requests = [];
  List<CoachOptionModel> coaches = [];
  List<ClassSessionModel> classes =
      []; // all classes (no past one-time) — for All Classes tab
  List<ClassSessionModel> weekClasses = []; // this week only — for Schedule tab
  AdminScheduleStatsModel? stats; // all-classes stats
  AdminScheduleStatsModel? weekStats; // this-week stats

  static const days = [
    'All',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  Future<void> loadAll(String token, int gymId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final today = DateTime.now();

    // Monday of this week
    final monday = today.subtract(Duration(days: today.weekday - 1));
    // Sunday of this week
    final sunday = monday.add(const Duration(days: 6));

    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final fromDate = fmt(today);
    final weekStart = fmt(monday);
    final weekEnd = fmt(sunday);

    try {
      final results = await Future.wait([
        _repo.getStats(token, gymId), // all stats
        _repo.getStats(token, gymId, weekOnly: true), // week stats
        _repo.getClasses(token, gymId, fromDate: fromDate), // All Classes tab
        _repo.getClasses(
          token,
          gymId,
          weekStart: weekStart,
          weekEnd: weekEnd,
        ), // Schedule tab
        _repo.getPendingRequests(token, gymId),
        _repo.getCoaches(token, gymId),
      ]);
      stats = results[0] as AdminScheduleStatsModel;
      weekStats = results[1] as AdminScheduleStatsModel;
      classes = results[2] as List<ClassSessionModel>;
      weekClasses = results[3] as List<ClassSessionModel>;
      requests = results[4] as List<ClassRequestModel>;
      coaches = results[5] as List<CoachOptionModel>;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setTab(int index) {
    selectedTab = index;
    errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void setDayFilter(String day) {
    selectedDay = day;
    notifyListeners();
  }

  bool _isPassedToday(ClassSessionModel c) {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final todayName = days[now.weekday - 1];

    final isToday = c.isRecurring
        ? c.dayOfWeek == todayName
        : c.date == todayStr;
    if (!isToday) return false;

    final parts = c.startTime.split(':');
    final classTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    return classTime.isBefore(now);
  }

  // All Classes tab uses classes (future + recurring only), minus today's already-started ones
  List<ClassSessionModel> get filteredClasses {
    final upcoming = classes.where((c) => !_isPassedToday(c)).toList();
    if (selectedDay == 'All') return upcoming;
    return upcoming.where((c) => c.dayOfWeek == selectedDay).toList();
  }

  // weeklySchedule stays exactly as-is — untouched, still shows the full week

  Map<String, List<ClassSessionModel>> get weeklySchedule {
    final map = <String, List<ClassSessionModel>>{};
    for (final day in days.skip(1)) {
      map[day] = weekClasses.where((c) => c.dayOfWeek == day).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return map;
  }

  Color capacityColor(ClassSessionModel c) {
    if (c.isFull) return Colors.red;
    if (c.fillRatio > 0.8) return Colors.orange;
    return const Color(0xFF4CAF50);
  }

  Future<bool> createClass(
    String token,
    int gymId,
    Map<String, dynamic> payload,
  ) async {
    final online = await ConnectivityHelper.isOnline();
    if(!online){
      errorMessage = 'You are offline. Please try again when you\'re connected.';
      notifyListeners();
      return false;
    }
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
    final online = await ConnectivityHelper.isOnline();
    if(!online){
      errorMessage = 'You are offline. Please try again when you\'re connected.';
      notifyListeners();
      return false;
    }
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
    final online = await ConnectivityHelper.isOnline();
    if(!online){
      errorMessage = 'You are offline. Please try again when you\'re connected.';
      notifyListeners();
      return false;
    }
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
      final online = await ConnectivityHelper.isOnline();
      if(!online){
        errorMessage = 'You are offline. Please try again when you\'re connected.';
        notifyListeners();
        return false;
    }
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
