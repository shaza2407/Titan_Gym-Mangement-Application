import 'package:flutter/material.dart';
import '../../data/announcement_repository.dart';
import '../../domain/announcement_model.dart';
import '../../../shared/connectivity_helper.dart';

class AnnouncementController extends ChangeNotifier {
  final AnnouncementRepository _repo = AnnouncementRepository();

  List<Announcement> announcements = [];
  bool isLoading    = false;
  bool isSubmitting = false;
  String? errorMessage;
  String? submitError;

  Future<void> loadAnnouncements({
    required String token,
    required int gymId,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      announcements = await _repo.getAnnouncements(
        token: token,
        gymId: gymId,
      );
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAnnouncement({
    required String token,
    required int gymId,
    required CreateAnnouncementRequest request,

  }) 
  async {
    final online = await ConnectivityHelper.isOnline();
    if(!online){
      errorMessage = 'You are offline. Please try again when you\'re connected.';
      notifyListeners();
      return false;
    }
    isSubmitting = true;
    submitError  = null;
    notifyListeners();
    try {
      await _repo.createAnnouncement(
        token:   token,
        gymId:   gymId,
        request: request,
      );
      return true;
    } catch (e) {
      submitError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}