import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import '../../shared/connectivity_helper.dart';
import '../domain/analytics_models.dart';

class AnalyticsService {
  final String token;
  final int gymId;

  AnalyticsService({required this.token, required this.gymId});

  String get _summaryKey          => 'cache_analytics_summary_$gymId';
  String get _revenueTrendKey     => 'cache_analytics_revenue_$gymId';
  String get _membersTrendKey     => 'cache_analytics_members_$gymId';
  String get _membershipDistKey   => 'cache_analytics_membership_dist_$gymId';
  String get _weeklyPatternKey    => 'cache_analytics_weekly_$gymId';

  Map<String, String> get _headers => {
    'content-type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<AnalyticsSummary> fetchSummary() async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_summaryKey);
      if (cached != null) return AnalyticsSummary.fromJson(jsonDecode(cached));
      throw Exception('You are offline and no cached summary available.');
    }

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/analytics/$gymId/summary'),
      headers: _headers,
    );
    _checkStatus(res);
    await CacheService.save(_summaryKey, res.body);
    return AnalyticsSummary.fromJson(jsonDecode(res.body));
  }

  Future<List<MonthRevenue>> fetchRevenueTrend() async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_revenueTrendKey);
      if (cached != null) {
        return (jsonDecode(cached)['months'] as List)
            .map((e) => MonthRevenue.fromJson(e))
            .toList();
      }
      throw Exception('You are offline and no cached revenue trend available.');
    }

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/analytics/$gymId/revenue-trend'),
      headers: _headers,
    );
    _checkStatus(res);
    await CacheService.save(_revenueTrendKey, res.body);
    return (jsonDecode(res.body)['months'] as List)
        .map((e) => MonthRevenue.fromJson(e))
        .toList();
  }

  Future<List<MonthMembers>> fetchMembersTrend() async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_membersTrendKey);
      if (cached != null) {
        return (jsonDecode(cached)['months'] as List)
            .map((e) => MonthMembers.fromJson(e))
            .toList();
      }
      throw Exception('You are offline and no cached members trend available.');
    }

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/analytics/$gymId/member-trend'),
      headers: _headers,
    );
    _checkStatus(res);
    await CacheService.save(_membersTrendKey, res.body);
    return (jsonDecode(res.body)['months'] as List)
        .map((e) => MonthMembers.fromJson(e))
        .toList();
  }

  Future<List<MembershipTypeCount>> fetchMembershipTypeDistribution() async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_membershipDistKey);
      if (cached != null) {
        return (jsonDecode(cached)['distribution'] as List)
            .map((e) => MembershipTypeCount.fromJson(e))
            .toList();
      }
      throw Exception('You are offline and no cached membership distribution available.');
    }

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/analytics/$gymId/membership-dist'),
      headers: _headers,
    );
    _checkStatus(res);
    await CacheService.save(_membershipDistKey, res.body);
    return (jsonDecode(res.body)['distribution'] as List)
        .map((e) => MembershipTypeCount.fromJson(e))
        .toList();
  }

  Future<List<DayPattern>> fetchWeeklyPattern() async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_weeklyPatternKey);
      if (cached != null) {
        return (jsonDecode(cached)['data'] as List)
            .map((e) => DayPattern.fromJson(e))
            .toList();
      }
      throw Exception('You are offline and no cached weekly pattern available.');
    }

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/analytics/$gymId/weekly-pattern'),
      headers: _headers,
    );
    _checkStatus(res);
    await CacheService.save(_weeklyPatternKey, res.body);
    return (jsonDecode(res.body)['data'] as List)
        .map((e) => DayPattern.fromJson(e))
        .toList();
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode != 200) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }
}