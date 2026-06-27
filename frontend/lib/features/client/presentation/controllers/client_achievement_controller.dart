// lib/features/client/presentation/controllers/client_achievement_controller.dart

import 'package:flutter/material.dart';
import '../../data/client_achievement_repository.dart';
import '../../domain/achievement_model.dart';

class ClientAchievementController extends ChangeNotifier {
  final ClientAchievementRepository _repo;

  ClientAchievementController() : _repo = ClientAchievementRepository();
  ClientAchievementController.withRepo(this._repo);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AchievementModel> _achievements = [];
  List<AchievementModel> get achievements => _achievements;

  Future<void> loadAchievements(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _achievements = await _repo.getAchievements(token);
    } catch (e) {
      _errorMessage = 'Failed to load achievements.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
