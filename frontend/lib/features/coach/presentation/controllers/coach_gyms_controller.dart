import 'package:flutter/material.dart';
import 'package:frontend/features/coach/data/coach_gyms_repository.dart';
import '../../domain/coach_gyms_model.dart';

class CoachGymsController extends ChangeNotifier {
  final CoachGymsRepository _repo = CoachGymsRepository();

  List<CoachGymModel> myGyms = [];
  List<CoachAnnouncementModel> announcements = [];
  bool isLoading = true;
  String? errorMessage;

  int get totalClients => myGyms.fold(0, (sum, gym) => sum + gym.clientsCount);
  int get totalClasses => myGyms.fold(0, (sum, gym) => sum + gym.classesCount);

  Future<void> loadAll(String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final results = await Future.wait([
      _safe(() async => myGyms = await _repo.getCoachGyms(token)),
      _safe(() async => announcements = await _repo.getGymAnnouncements(token)),
    ]);

    final allFailed = results.every((ok) => ok == false);
    if (allFailed && myGyms.isEmpty && announcements.isEmpty) {
      errorMessage =
          'Unable to load your gyms. Check your connection and try again.';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> _safe(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class GymAnnouncementsController extends ChangeNotifier {
  final CoachGymsRepository _repo = CoachGymsRepository();

  List<CoachAnnouncementModel> announcements = [];
  bool isLoading = true;
  String? errorMessage;

  Future<void> loadGymAnnouncements(String token, int gymId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      announcements = await _repo.getGymAnnouncements(token, gymId: gymId);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
