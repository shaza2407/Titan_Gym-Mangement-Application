import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import '../domain/analytics_models.dart';

class AnalyticsService {
  final String token;
  final int gymId;

  AnalyticsService({required this.token, required this.gymId});

  Map<String, String> get _headers => {
    'content-type': 'application/json',
    'Authorization': 'Bearer $token'
  };


  Future<AnalyticsSummary> fetchSummary() async {
    final url = '${ApiConstants.baseUrl}/admin/analytics/$gymId/summary';
    final res = await http.get(Uri.parse(url), headers: _headers);
    // print("DEBUG: Received Summary ${res.body}");
    _checkStatus(res);
    return AnalyticsSummary.fromJson(jsonDecode(res.body));
  }

  Future<List<MonthRevenue>> fetchRevenueTrend() async {
    final url = '${ApiConstants.baseUrl}/admin/analytics/$gymId/revenue-trend';
    final res = await http.get(Uri.parse(url), headers: _headers);
    _checkStatus(res);
    return (jsonDecode(res.body)['months'] as List).map((e) => MonthRevenue.fromJson(e)).toList();
  }

  Future<List<MonthMembers>> fetchMembersTrend() async {
    final url = '${ApiConstants.baseUrl}/admin/analytics/$gymId/member-trend';
    final res = await http.get(Uri.parse(url), headers: _headers);
    _checkStatus(res);
    return (jsonDecode(res.body)['months'] as List).map((e) => MonthMembers.fromJson(e)).toList();
  }

  Future<List<MembershipTypeCount>> fetchMembershipTypeDistribution() async {
    final url = '${ApiConstants.baseUrl}/admin/analytics/$gymId/membership-dist';
    final res = await http.get(Uri.parse(url), headers: _headers);
    _checkStatus(res);
    return (jsonDecode(res.body)['distribution'] as List).map((e) => MembershipTypeCount.fromJson(e)).toList();
  }

  Future<List<DayPattern>> fetchWeeklyPattern() async {
    final url = '${ApiConstants.baseUrl}/admin/analytics/$gymId/weekly-pattern';
    final res = await http.get(Uri.parse(url), headers: _headers);
    _checkStatus(res);
    return (jsonDecode(res.body)['data'] as List).map((e) => DayPattern.fromJson(e)).toList();
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode != 200) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }
}