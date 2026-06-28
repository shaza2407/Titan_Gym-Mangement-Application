import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import '../../shared/connectivity_helper.dart';
import '../domain/attendance_models.dart';

class AttendanceAnalyticsService {
  final String token;
  final int gymId;

  AttendanceAnalyticsService({required this.token, required this.gymId});

  String get _statsKey    => 'cache_attendance_stats_$gymId';
  String get _weeklyKey   => 'cache_attendance_weekly_$gymId';
  // QR code is intentionally not cached — it must always be live

  Map<String, String> get _headers => {
    'content-type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<AttendanceStats> fetchStats() async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_statsKey);
      if (cached != null) return AttendanceStats.fromJson(jsonDecode(cached));
      throw Exception('You are offline and no cached attendance stats available.');
    }

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/attendance/$gymId/stats'),
      headers: _headers,
    );
    _checkStatus(res);
    await CacheService.save(_statsKey, res.body);
    return AttendanceStats.fromJson(jsonDecode(res.body));
  }

  Future<QRCodeInfo> fetchQRCode() async {
    // No caching — QR codes are time-sensitive and must always be live
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/attendance/$gymId/qr-code'),
      headers: _headers,
    );
    _checkStatus(res);
    return QRCodeInfo.fromJson(jsonDecode(res.body));
  }

  Future<WeeklyAttendance> fetchWeeklyAttendance() async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_weeklyKey);
      if (cached != null) return WeeklyAttendance.fromJson(jsonDecode(cached));
      throw Exception('You are offline and no cached weekly attendance available.');
    }

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/attendance/$gymId/weekly'),
      headers: _headers,
    );
    _checkStatus(res);
    await CacheService.save(_weeklyKey, res.body);
    return WeeklyAttendance.fromJson(jsonDecode(res.body));
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode != 200) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }
}