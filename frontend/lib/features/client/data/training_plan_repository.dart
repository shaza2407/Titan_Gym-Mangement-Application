// lib/features/client/data/training_plan_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import '../domain/training_plan_model.dart';


class TrainingPlanRepository {
  static const _summariesCacheKey = 'client_training_plan_summaries';
  static const _activePlanCacheKeyPrefix = 'client_training_plan_active_';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<TrainingPlanSummaryModel>> listTrainingPlans(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/training-plans/'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('Failed to load training plans');
      }
      await CacheService.save(_summariesCacheKey, res.body);
      final List list = jsonDecode(res.body);
      return list.map((e) => TrainingPlanSummaryModel.fromJson(e)).toList();
    } catch (e) {
      final cached = await CacheService.load(_summariesCacheKey);
      if (cached != null) {
        final List list = jsonDecode(cached);
        return list.map((e) => TrainingPlanSummaryModel.fromJson(e)).toList();
      }
      throw Exception(
        'Unable to load your training plans. Check your connection.',
      );
    }
  }

  Future<TrainingPlanModel> getTrainingPlan(String token, int planId) async {
    final cacheKey = '$_activePlanCacheKeyPrefix$planId';
    try {
      final res = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/training-plans/$planId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('Failed to load training plan details');
      }
      await CacheService.save(cacheKey, res.body);
      return TrainingPlanModel.fromJson(jsonDecode(res.body));
    } catch (e) {
      final cached = await CacheService.load(cacheKey);
      if (cached != null) return TrainingPlanModel.fromJson(jsonDecode(cached));
      throw Exception(
        'Unable to load this plan\'s details. Check your connection.',
      );
    }
  }

  // ── Writes below: never cached, never fall back. Each fails with a clean
  // message so the controller doesn't surface a raw timeout/socket string. ──

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

    try {
      final res = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/training-plans/generate'),
            headers: _headers(token),
            body: jsonEncode(body),
          )
          // AI generation is slow — give it real room, but still bounded.
          .timeout(const Duration(seconds: 60));

      if (res.statusCode == 201 || res.statusCode == 200) {
        return TrainingPlanModel.fromJson(jsonDecode(res.body));
      }
      final error = jsonDecode(res.body);
      throw Exception(error['detail'] ?? 'Failed to generate training plan');
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('Server is busy') || errorStr.contains('Failed to generate')) {
        rethrow;
      }
      throw Exception(
        'Could not generate your plan — check your connection and try again.',
      );
    }
  }

  Future<void> completeDay({
    required String token,
    required int planId,
    required int weekNumber,
    required int dayNumber,
    required int completedExercises,
    required int totalExercises,
    required int durationMinutes,
    required List<int> completedExerciseIndices,
  }) async {
    final body = {
      'week_number': weekNumber,
      'day_number': dayNumber,
      'completed_exercises': completedExercises,
      'total_exercises': totalExercises,
      'duration_minutes': durationMinutes,
      'completed_exercise_indices': completedExerciseIndices,
    };

    try {
      final res = await http
          .post(
            Uri.parse(
              '${ApiConstants.baseUrl}/training-plans/$planId/complete-day',
            ),
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        final error = jsonDecode(res.body);
        throw Exception(error['detail'] ?? 'Failed to complete workout day');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('detail')) rethrow;
      throw Exception(
        'Could not log this workout — check your connection and try again.',
      );
    }
  }

  Future<void> completeWeek(String token, int planId, int weekNumber) async {
    try {
      final res = await http
          .post(
            Uri.parse(
              '${ApiConstants.baseUrl}/training-plans/$planId/complete-week',
            ),
            headers: _headers(token),
            body: jsonEncode({'week_number': weekNumber}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        final error = jsonDecode(res.body);
        throw Exception(error['detail'] ?? 'Failed to complete week');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('detail')) rethrow;
      throw Exception(
        'Could not complete this week — check your connection and try again.',
      );
    }
  }

  Future<void> completeTrainingPlan(String token, int planId) async {
    try {
      final res = await http
          .patch(
            Uri.parse(
              '${ApiConstants.baseUrl}/training-plans/$planId/complete',
            ),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('Failed to complete training plan');
      }
    } catch (e) {
      throw Exception(
        'Could not complete this plan — check your connection and try again.',
      );
    }
  }

  Future<void> deleteTrainingPlan(String token, int planId) async {
    try {
      final res = await http
          .delete(
            Uri.parse('${ApiConstants.baseUrl}/training-plans/$planId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 204) {
        throw Exception('Failed to delete training plan');
      }
    } catch (e) {
      throw Exception(
        'Could not delete this plan — check your connection and try again.',
      );
    }
  }
}
