import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/attendance_model.dart';
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';

class CheckinStatusResult {
  final CheckinStatusModel status;
  final bool isLive;
  CheckinStatusResult(this.status, this.isLive);
}

class AttendanceRepository {
  static const _statusCacheKey = 'client_checkin_status';
  static const _historyCacheKey = 'client_recent_checkins';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<CheckinStatusResult> getCheckinStatus(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/client/checkin-status'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('Failed to get check-in status');
      }
      await CacheService.save(_statusCacheKey, res.body);
      return CheckinStatusResult(
        CheckinStatusModel.fromJson(jsonDecode(res.body)),
        true,
      );
    } catch (e) {
      final cached = await CacheService.load(_statusCacheKey);
      if (cached != null) {
        return CheckinStatusResult(
          CheckinStatusModel.fromJson(jsonDecode(cached)),
          false,
        );
      }
      throw Exception('Unable to load check-in status. Check your connection.');
    }
  }

  Future<List<AttendanceModel>> getRecentCheckins(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/client/checkins'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('Failed to get check-in history');
      }
      await CacheService.save(_historyCacheKey, res.body);
      final data = jsonDecode(res.body);
      return (data['checkins'] as List)
          .map((e) => AttendanceModel.fromJson(e))
          .toList();
    } catch (e) {
      final cached = await CacheService.load(_historyCacheKey);
      if (cached != null) {
        final data = jsonDecode(cached);
        return (data['checkins'] as List)
            .map((e) => AttendanceModel.fromJson(e))
            .toList();
      }
      throw Exception(
        'Unable to load check-in history. Check your connection.',
      );
    }
  }

  Future<String> doCheckin(String token, String qrCode) async {
    http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/client/checkin'),
            headers: _headers(token),
            body: jsonEncode({'qr_code': qrCode}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw Exception(
        'Could not check in — check your connection and try again.',
      );
    }

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['checked_in'];
    }

    // Got a real response from the server — surface its actual message.
    String message = 'Check-in failed';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['detail'] != null) {
        message = body['detail'].toString();
      }
    } catch (_) {
      // response wasn't valid JSON — keep default message
    }
    throw Exception(message);
  }
}
