import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import '../domain/gym_model.dart';

class ClientGymRepository {
  final String baseUrl = ApiConstants.baseUrl;

  Future<GymInfoModel> getMyGym(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/client/gym'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw Exception('Failed to load gym info');
    return GymInfoModel.fromJson(jsonDecode(res.body));
  }

  Future<List<AnnouncementModel>> getAnnouncements(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/client/gym/announcements'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw Exception('Failed to load announcements');
    final List data = jsonDecode(res.body);
    return data.map((e) => AnnouncementModel.fromJson(e)).toList();
  }

  Future<Map<String, List<GymClassModel>>> getWeeklySchedule(
    String token,
  ) async {
    final res = await http.get(
      Uri.parse('$baseUrl/client/gym/weekly-schedule'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw Exception('Failed to load schedule');
    final Map<String, dynamic> data = jsonDecode(res.body);
    return data.map((day, classes) {
      final list = (classes as List)
          .map((c) => GymClassModel.fromJson(c))
          .toList();
      return MapEntry(day, list);
    });
  }
}
