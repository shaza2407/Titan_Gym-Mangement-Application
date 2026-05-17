import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../domain/dashboard_model.dart';

class DashboardRepository {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000'; // Chrome / web
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000'; // Android emulator
    } else if (Platform.isIOS) {
      return 'http://localhost:8000'; // iOS simulator
    }
    return 'http://localhost:8000';
  }

  Future<DashboardStatsModel> getDashboardStats(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/client/dashboard-stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      return DashboardStatsModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load dashboard stats');
  }
}
