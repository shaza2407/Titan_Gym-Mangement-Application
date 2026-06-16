import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/attendance_model.dart';
import '../../shared/api_constants.dart';

class AttendanceRepository {
  Future<CheckinStatusModel> getCheckinStatus(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/client/checkin-status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      return CheckinStatusModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to get check-in status');
  }

  Future<String> doCheckin(String token, String qrCode) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/client/checkin'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'qr_code': qrCode}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['checked_in'];
    }
    throw Exception(jsonDecode(res.body)['detail'] ?? 'Check-in failed');
  }

  Future<List<AttendanceModel>> getRecentCheckins(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/client/checkins'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['checkins'] as List)
          .map((e) => AttendanceModel.fromJson(e))
          .toList();
    }
    throw Exception('Failed to get check-in history');
  }
}
