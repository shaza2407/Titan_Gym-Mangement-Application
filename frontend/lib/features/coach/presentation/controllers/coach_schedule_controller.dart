import 'package:flutter/material.dart';
import '../../data/coach_schedule_repository.dart';
import '../../domain/coach_schedule_model.dart';

class CoachScheduleController extends ChangeNotifier {
  final CoachScheduleRepository _repo = CoachScheduleRepository();

  CoachScheduleStatsModel? stats;
  List<CoachWeeklyDayModel> weekly = [];
  List<CoachClassModel> myClasses = [];
  List<CoachClassRequestModel> requests = [];
  List<CoachGymLookupModel> gyms = [];

  bool isLoading = false;
  bool isSubmitting = false;
  bool isLoadingGyms = false;
  String? errorMessage;

  int selectedTab = 0; // 0=Schedule, 1=MyClasses, 2=Requests
  int? selectedGymId;

  // Request form fields
  final classNameController = TextEditingController();
  final durationController = TextEditingController();
  final maxCapacityController = TextEditingController();
  final reasonController = TextEditingController();
  bool isRecurring = true;
  String? selectedDay;
  String? selectedDate;
  String? selectedTime;

  final List<String> days = [
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

    try {
      stats = await _repo.getStats(token);
      weekly = await _repo.getWeekly(token);
      myClasses = await _repo.getMyClasses(token);
      requests = await _repo.getRequests(token);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitRequest(String token) async {
    if (classNameController.text.trim().isEmpty ||
        selectedTime == null ||
        selectedGymId == null) {
      errorMessage = 'Please fill all required fields';
      notifyListeners();
      return false;
    }

    final duration = int.tryParse(durationController.text.trim());
  if (duration == null || duration <= 0) {
    errorMessage = 'Please enter a valid session duration';
    notifyListeners();
    return false;
  }

  final maxCapacity = int.tryParse(maxCapacityController.text.trim());
  if (maxCapacity == null || maxCapacity <= 0) {
    errorMessage = 'Please enter a valid max capacity';
    notifyListeners();
    return false;
  }

    if (isRecurring && selectedDay == null) {
      errorMessage = 'Please select a day for the recurring class';
      notifyListeners();
      return false;
    }

    if (!isRecurring && selectedDate == null) {
      errorMessage = 'Please pick a start date from the calendar';
      notifyListeners();
      return false;
    }

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = {
        'class_name': classNameController.text.trim(),
        'gym_id': selectedGymId,
        'is_recurring': isRecurring,
        'day_of_week': isRecurring ? selectedDay : null,
        'requested_date': isRecurring ? null : selectedDate,
        'requested_time': selectedTime,
        'duration': int.tryParse(durationController.text.trim()),
        'max_capacity': int.tryParse(maxCapacityController.text.trim()),
        'reason': reasonController.text.trim()
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
    selectedGymId = null;
    selectedDay = null;
    selectedDate = null;
    selectedTime = null;
    isRecurring = true;
  }

  void setTab(int index) {
    selectedTab = index;
    notifyListeners();
  }

  void setRecurring(bool value) {
    isRecurring = value;
    selectedDay = null;
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

  Future<bool> deleteClass(String token, int classId) async {
    try {
      await _repo.removeClass(token, classId);

      // Remove locally
      myClasses.removeWhere((c) => c.id == classId);

      // Refresh stats/schedule if needed
      await loadAll(token);

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // -Added method to load gyms for request form-
  Future<void> loadGyms(String token) async {
    isLoadingGyms = true;
    errorMessage = null;
    notifyListeners();
    try{
      gyms = await _repo.getGyms(token);
    } catch (e) {
      errorMessage = e.toString();
    }
    finally {
      isLoadingGyms = false;
      notifyListeners();
    }
  }

  // -Added method to set selected gym for request form-
  void selectGym(int? gymId) {
    selectedGymId = gymId;
    notifyListeners();
  }

  // -Added method to delete a class request-
  Future<bool> deleteRequest(String token, int requestId) async{
    try{
      await _repo.removeRequest(token, requestId);
      requests.removeWhere((r) => r.id == requestId);
      await loadAll(token);
      return true;
    }catch(e){
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

}
