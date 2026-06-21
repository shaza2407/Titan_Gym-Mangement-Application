import 'package:flutter/material.dart';
import 'package:frontend/features/coach/data/coach_gyms_repository.dart';
import '../../domain/coach_gyms_model.dart';

class CoachGymsController extends ChangeNotifier {
  final CoachGymsRepository _repo = CoachGymsRepository();

  List<CoachGymModel> myGyms = [];
  List<CoachAnnouncementModel> announcements = [];
  bool isLoading = true;

  int get totalClients => myGyms.fold(0, (sum, gym) => sum + gym.clientsCount);
  int get totalClasses => myGyms.fold(0, (sum, gym) => sum + gym.classesCount);

  Future<void> loadAll(String token) async {
    isLoading = true;
    notifyListeners();

    try {
      myGyms = await _repo.getCoachGyms(token);
      announcements = await _repo.getGymAnnouncements(token);
    } catch (e) {
      print('Error loading gyms: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class GymAnnouncementsController extends ChangeNotifier {
  final CoachGymsRepository _repo = CoachGymsRepository();

  List<CoachAnnouncementModel> announcements = [];
  bool isLoading = true;

  Future<void> loadGymAnnouncements(String token, int gymId) async {
    isLoading = true;
    notifyListeners();
    try {
      announcements = await _repo.getGymAnnouncements(token, gymId: gymId);
    } catch (e) {
      debugPrint('Error loading gym announcements: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
