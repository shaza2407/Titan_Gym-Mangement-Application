import 'package:flutter/material.dart';
import '../../domain/analytics_models.dart';
import '../../data/analytics_repository.dart';

class AnalyticsController extends ChangeNotifier {
  AnalyticsSummary?          summary;
  List<MonthRevenue>?        revenueTrend;
  List<MonthMembers>?        memberTrend;
  List<MembershipTypeCount>? membershipDist;
  List<DayPattern>?          weeklyPattern;

  bool    loading = true;
  String? error;

  Future<void> loadAll(String token, int gymId) async {
    loading = true;
    error   = null;
    notifyListeners();

    try {
      final service = AnalyticsService(token: token, gymId: gymId);

      final results = await Future.wait([
        service.fetchSummary(),
        service.fetchRevenueTrend(),
        service.fetchMembersTrend(),
        service.fetchMembershipTypeDistribution(),
        service.fetchWeeklyPattern(),
      ]);

      summary        = results[0] as AnalyticsSummary;
      revenueTrend   = results[1] as List<MonthRevenue>;
      memberTrend    = results[2] as List<MonthMembers>;
      membershipDist = results[3] as List<MembershipTypeCount>;
      weeklyPattern  = results[4] as List<DayPattern>;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}