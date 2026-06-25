import 'package:flutter/material.dart';
import '../../data/gym_stats_repository.dart';
import '../../domain/gym_stats_model.dart';

class GymStatsController extends ChangeNotifier {
  final GymStatsRepository _repo = GymStatsRepository();

  int totalMembers = 0;
  bool isLoadingTotalMembers = false;

  Map<int, GymStats> gymStatsCache = {};
  bool isLoadingGymStats = false;

  Future<void> loadTotalMembers({required String token}) async {
    isLoadingTotalMembers = true;
    notifyListeners();
    try {
      totalMembers = await _repo.getTotalMembers(token: token);
    } catch (_) {
      totalMembers = 0;
    } finally {
      isLoadingTotalMembers = false;
      notifyListeners();
    }
  }

  Future<void> loadAllGymStats({
    required String token,
    required List<int> gymIds,
  }) async {
    isLoadingGymStats = true;
    notifyListeners();
    try {
      final results = await Future.wait(
        gymIds.map((gymId) async {
          final members = await _repo.getGymMemberCount(token: token, gymId: gymId);
          final coaches = await _repo.getGymCoachCount(token: token, gymId: gymId);
          return GymStats(
            gymId:       gymId,
            memberCount: members,
            coachCount:  coaches,
          );
        }),
      );
      for (final stats in results) {
        gymStatsCache[stats.gymId] = stats;
      }
    } catch (_) {
      // non-critical, cache stays at previous values
    } finally {
      isLoadingGymStats = false;
      notifyListeners();
    }
  }

  int memberCount(int gymId) => gymStatsCache[gymId]?.memberCount ?? 0;
  int coachCount(int gymId)  => gymStatsCache[gymId]?.coachCount  ?? 0;
}