// lib/features/client/data/training_plan_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import '../domain/training_plan_model.dart';

class TrainingPlanRepository {
  Future<List<TrainingPlanSummaryModel>> listTrainingPlans(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/training-plans/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => TrainingPlanSummaryModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load training plans');
  }

  Future<TrainingPlanModel> getTrainingPlan(String token, int planId) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/training-plans/$planId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      return TrainingPlanModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load training plan details');
  }

  Future<TrainingPlanModel> generateTrainingPlan({
    required String token,
    required String goal,
    required String level,
    required int weeks,
    required int daysPerWeek,
    required String equipment,
    required String injuries,
  }) async {
    final body = {
      'fitness_goal': goal,
      'level': level,
      'weeks': weeks,
      'days_per_week': daysPerWeek,
      'equipment': equipment,
      'injuries': injuries.trim().isEmpty ? null : injuries,
    };

    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/training-plans/generate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      return TrainingPlanModel.fromJson(jsonDecode(res.body));
    }
    final error = jsonDecode(res.body);
    throw Exception(error['detail'] ?? 'Failed to generate training plan');
  }

  Future<void> completeDay({
    required String token,
    required int planId,
    required String trackingDate, // "YYYY-MM-DD"
    required int completedExercises,
    required int totalExercises,
    required int durationMinutes,
  }) async {
    final body = {
      'tracking_date': trackingDate,
      'completed_exercises': completedExercises,
      'total_exercises': totalExercises,
      'duration_minutes': durationMinutes,
    };

    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/training-plans/$planId/complete-day'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      final error = jsonDecode(res.body);
      throw Exception(error['detail'] ?? 'Failed to complete workout day');
    }
  }

  Future<void> completeTrainingPlan(String token, int planId) async {
    final res = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/training-plans/$planId/complete'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to complete training plan');
    }
  }

  Future<void> deleteTrainingPlan(String token, int planId) async {
    final res = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/training-plans/$planId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 204) {
      throw Exception('Failed to delete training plan');
    }
  }
}
