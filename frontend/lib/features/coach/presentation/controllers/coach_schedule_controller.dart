import 'package:flutter/material.dart';
import '../../data/coach_schedule_repository.dart';
import '../../domain/coach_schedule_model.dart';

class CoachScheduleController extends ChangeNotifier {
  final CoachScheduleRepository _repo = CoachScheduleRepository();

  CoachScheduleStatsModel? stats;
  List<CoachWeeklyDayModel> weekly   = [];
  List<CoachClassModel> myClasses    = [];
  List<CoachClassRequestModel> requests = [];

  bool isLoading      = false;
  bool isSubmitting   = false;
  String? errorMessage;

  int selectedTab = 0; // 0=Schedule, 1=MyClasses, 2=Requests

  // Request form fields
  final classNameController    = TextEditingController();
  final durationController     = TextEditingController();
  final maxCapacityController  = TextEditingController();
  final reasonController       = TextEditingController();
  bool isRecurring             = true;
  String? selectedDay;
  String? selectedDate;
  String? selectedTime;

  final List<String> days = [
    'monday', 'tuesday', 'wednesday', 'thursday',
    'friday', 'saturday', 'sunday'
  ];

  Future<void> loadAll(String token) async {
    isLoading    = true;
    errorMessage = null;
    notifyListeners();

    try {
      stats     = await _repo.getStats(token);
      weekly    = await _repo.getWeekly(token);
      myClasses = await _repo.getMyClasses(token);
      requests  = await _repo.getRequests(token);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitRequest(String token) async {
    if (classNameController.text.trim().isEmpty || selectedTime == null) {
      errorMessage = 'Please fill all required fields';
      notifyListeners();
      return false;
    }

    if (isRecurring && selectedDay == null) {
      errorMessage = 'Please select a day for recurring class';
      notifyListeners();
      return false;
    }

    if (!isRecurring && selectedDate == null) {
      errorMessage = 'Please select a date for one-time class';
      notifyListeners();
      return false;
    }

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = {
        'class_name':     classNameController.text.trim(),
        'is_recurring':   isRecurring,
        'day_of_week':    isRecurring ? selectedDay : null,
        'requested_date': !isRecurring ? selectedDate : null,
        'requested_time': selectedTime,
        'duration':       int.tryParse(durationController.text.trim()) ?? 45,
        'max_capacity':   int.tryParse(maxCapacityController.text.trim()) ?? 20,
        'reason':         reasonController.text.trim().isEmpty
            ? null
            : reasonController.text.trim(),
      };
      await _repo.createRequest(token, data);
      await loadAll(token);
      _resetForm();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void _resetForm() {
    classNameController.clear();
    durationController.clear();
    maxCapacityController.clear();
    reasonController.clear();
    selectedDay  = null;
    selectedDate = null;
    selectedTime = null;
    isRecurring  = true;
  }

  void setTab(int index) {
    selectedTab = index;
    notifyListeners();
  }

  void setRecurring(bool value) {
    isRecurring  = value;
    selectedDay  = null;
    selectedDate = null;
    notifyListeners();
  }

  void setDay(String? value) {
    selectedDay = value;
    notifyListeners();
  }

  void setDate(String value) {
    selectedDate = value;
    notifyListeners();
  }

  void setTime(String value) {
    selectedTime = value;
    notifyListeners();
  }
}