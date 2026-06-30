import 'package:flutter/material.dart';
import '../../data/client_gym_repository.dart';
import '../../domain/gym_model.dart';

class ClientGymController extends ChangeNotifier {
  final ClientGymRepository _repo = ClientGymRepository();

  bool isLoading = true;
  String? errorMessage;

  GymInfoModel? gym;
  List<AnnouncementModel> announcements = [];
  Map<String, List<GymClassModel>> weeklySchedule = {};

  static const dayNames = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  Future<void> loadAll(String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final results = await Future.wait([
      _safeLoadGym(token),
      _safeLoadAnnouncements(token),
      _safeLoadSchedule(token),
    ]);

    final allFailed = results.every((success) => success == false);
    if (allFailed &&
        gym == null &&
        announcements.isEmpty &&
        weeklySchedule.isEmpty) {
      errorMessage =
          'Unable to load gym info. Check your connection and try again.';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> _safeLoadGym(String token) async {
    try {
      gym = await _repo.getMyGym(token);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _safeLoadAnnouncements(String token) async {
    try {
      announcements = await _repo.getAnnouncements(token);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _safeLoadSchedule(String token) async {
    try {
      weeklySchedule = await _repo.getWeeklySchedule(token);
      return true;
    } catch (_) {
      return false;
    }
  }
}
