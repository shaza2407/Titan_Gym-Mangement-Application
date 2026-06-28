import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import '../../shared/connectivity_helper.dart';
import '../domain/attendance_models.dart';

class AttendanceRepository {
  final String token;
  final int gymId;

  AttendanceRepository({required this.token, required this.gymId});

  String get _statsKey   => 'cache_attendance_stats_$gymId';
  String get _weeklyKey  => 'cache_attendance_weekly_$gymId';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
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
    if (res.statusCode != 200) throw Exception('API error ${res.statusCode}');
    await CacheService.save(_statsKey, res.body);
    return AttendanceStats.fromJson(jsonDecode(res.body));
  }

  Future<QRCodeInfo> fetchQRCode() async {
    // No caching — QR codes must always be live
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/attendance/$gymId/qr-code'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('API error ${res.statusCode}');
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
    if (res.statusCode != 200) throw Exception('API error ${res.statusCode}');
    await CacheService.save(_weeklyKey, res.body);
    return WeeklyAttendance.fromJson(jsonDecode(res.body));
  }
}