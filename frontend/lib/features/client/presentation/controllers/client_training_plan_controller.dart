// lib/features/client/presentation/controllers/client_training_plan_controller.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../data/training_plan_repository.dart';
import '../../domain/training_plan_model.dart';

class ClientTrainingPlanController extends ChangeNotifier {
  final TrainingPlanRepository _repo = TrainingPlanRepository();

  bool isLoading = false;
  bool isGenerating = false;
  String? errorMessage;

  List<TrainingPlanSummaryModel> summaries = [];
  TrainingPlanModel? activePlan;
  int selectedWeekNumber = 1;

  // Form parameters for plan generation
  String selectedGoal = 'Muscle Gain';
  String selectedLevel = 'beginner';
  int selectedWeeks = 8;
  int selectedDaysPerWeek = 4;
  String selectedEquipment = 'Full Gym';
  final TextEditingController injuriesController = TextEditingController();

  final List<String> goals = [
    'Muscle Gain',
    'Weight Loss',
    'Cardio/Endurance',
    'Flexibility',
    'Overall Fitness'
  ];

  final List<String> levels = ['beginner', 'intermediate', 'advanced'];
  final List<int> weekOptions = [4, 8, 12, 16];
  final List<int> daysPerWeekOptions = [3, 4, 5, 6];
  final List<String> equipmentOptions = ['Full Gym', 'Home/Bodyweight', 'Dumbbells Only'];

  void setGoal(String val) {
    selectedGoal = val;
    notifyListeners();
  }

  void setLevel(String val) {
    selectedLevel = val;
    notifyListeners();
  }

  void setWeeks(int val) {
    selectedWeeks = val;
    notifyListeners();
  }

  void setDaysPerWeek(int val) {
    selectedDaysPerWeek = val;
    notifyListeners();
  }

  void setEquipment(String val) {
    selectedEquipment = val;
    notifyListeners();
  }

  void setSelectedWeek(int weekNum) {
    selectedWeekNumber = weekNum;
    notifyListeners();
  }

  Future<void> loadActivePlan(String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      summaries = await _repo.listTrainingPlans(token);
      final activeSummaries = summaries.where((s) => s.isActive && s.status != 'COMPLETED').toList();

      if (activeSummaries.isNotEmpty) {
        activePlan = await _repo.getTrainingPlan(token, activeSummaries.first.planID);
        // Default to first week of the plan
        if (activePlan != null && activePlan!.plan.isNotEmpty) {
          selectedWeekNumber = activePlan!.plan.first.week;
        }
      } else {
        activePlan = null;
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> generatePlan(String token) async {
    isGenerating = true;
    errorMessage = null;
    notifyListeners();

    try {
      final newPlan = await _repo.generateTrainingPlan(
        token: token,
        goal: selectedGoal,
        level: selectedLevel,
        weeks: selectedWeeks,
        daysPerWeek: selectedDaysPerWeek,
        equipment: selectedEquipment,
        injuries: injuriesController.text,
      );
      activePlan = newPlan;
      if (newPlan.plan.isNotEmpty) {
        selectedWeekNumber = newPlan.plan.first.week;
      }
      // Reload summaries
      summaries = await _repo.listTrainingPlans(token);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  Future<bool> toggleExerciseCompletion(int dayIndex, int exerciseIndex) async {
    if (activePlan == null || activePlan!.plan.isEmpty) return false;
    
    final week = activePlan!.plan.firstWhere(
      (w) => w.week == selectedWeekNumber,
      orElse: () => activePlan!.plan.first,
    );
    final day = week.days[dayIndex];
    final exercise = day.exercises[exerciseIndex];
    
    exercise.isCompleted = !exercise.isCompleted;
    
    // Recalculate day completion
    final total = day.exercises.length;
    final completed = day.exercises.where((e) => e.isCompleted).length;
    day.isCompleted = (completed == total && total > 0);
    
    notifyListeners();
    return true;
  }

  Future<bool> logDayCompletion({
    required String token,
    required int dayIndex,
    required int durationMinutes,
  }) async {
    if (activePlan == null || activePlan!.plan.isEmpty) return false;

    try {
      final week = activePlan!.plan.firstWhere(
        (w) => w.week == selectedWeekNumber,
        orElse: () => activePlan!.plan.first,
      );
      final day = week.days[dayIndex];
      final total = day.exercises.length;
      final completed = day.exercises.where((e) => e.isCompleted).length;

      // Call API
      await _repo.completeDay(
        token: token,
        planId: activePlan!.planID,
        weekNumber: selectedWeekNumber,
        dayNumber: dayIndex + 1,
        completedExercises: completed,
        totalExercises: total,
        durationMinutes: durationMinutes,
      );

      day.isCompleted = true;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completePlan(String token) async {
    if (activePlan == null) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repo.completeTrainingPlan(token, activePlan!.planID);
      activePlan = null;
      summaries = await _repo.listTrainingPlans(token);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePlan(String token, int planId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repo.deleteTrainingPlan(token, planId);
      if (activePlan?.planID == planId) {
        activePlan = null;
      }
      summaries = await _repo.listTrainingPlans(token);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> downloadPlanPdf(String token) async {
    if (activePlan == null) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse('http://127.0.0.1:8000/training-plans/${activePlan!.planID}/pdf'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/training_plan_${activePlan!.planID}.pdf');
        await file.writeAsBytes(res.bodyBytes);
        await OpenFilex.open(file.path);
      } else {
        errorMessage = 'Failed to download PDF.';
      }
    } catch (e) {
      errorMessage = 'Error saving PDF: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    injuriesController.dispose();
    super.dispose();
  }
}
