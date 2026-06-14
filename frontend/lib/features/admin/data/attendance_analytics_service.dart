import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import 'attendance_analytics_models.dart';


class AttendanceAnalyticsService {
  final String token;
  final int gymId;

  AttendanceAnalyticsService({required this.token, required this.gymId});

  Map<String, String> get _headers => {
    'content-type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<AttendanceStats> fetchStats() async {
    final url = '${ApiConstants.baseUrl}/admin/attendance/$gymId/stats';
    final res = await http.get(Uri.parse(url), headers: _headers);
    _checkStatus(res);
    return AttendanceStats.fromJson(jsonDecode(res.body));
  }

  Future<QRCodeInfo> fetchQRCode() async {
    final url = '${ApiConstants.baseUrl}/admin/attendance/$gymId/qr-code';
    final res = await http.get(Uri.parse(url), headers: _headers);
    _checkStatus(res);
    return QRCodeInfo.fromJson(jsonDecode(res.body));
  }

  Future<WeeklyAttendance> fetchWeeklyAttendance() async {
    final url = '${ApiConstants.baseUrl}/admin/attendance/$gymId/weekly';
    final res = await http.get(Uri.parse(url), headers: _headers);
    _checkStatus(res);
    return WeeklyAttendance.fromJson(jsonDecode(res.body));
  }


  void _checkStatus(http.Response res) {
    if (res.statusCode != 200) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }
}