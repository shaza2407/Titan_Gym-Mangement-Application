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
    try {
      final gymFuture = _repo.getMyGym(token);
      final announcementsFuture = _repo.getAnnouncements(token);
      final scheduleFuture = _repo.getWeeklySchedule(token);

      gym = await gymFuture;
      announcements = await announcementsFuture;
      weeklySchedule = await scheduleFuture;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
