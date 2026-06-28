import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';
import '../../domain/coach_model.dart';
import '../../../shared/connectivity_helper.dart';
class CoachManagementController extends ChangeNotifier {
  final AdminRepository _repo = AdminRepository();

  CoachListResponse? data;
  bool isLoading = false;
  String? errorMessage;
  String selectedFilter = 'all';
  String searchQuery    = '';

  final searchController = TextEditingController();

  List<CoachListItem> get filtered {
    final coaches = data?.coaches ?? [];
    return coaches.where((c) {
      final matchFilter =
          selectedFilter == 'all' || c.status == selectedFilter;
      final matchSearch = searchQuery.isEmpty ||
          c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          c.email.toLowerCase().contains(searchQuery.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();
  }

  Future<void> loadCoaches({
    required int gymId,
    required String token,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      data = await _repo.fetchCoaches(gymId, token);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> suspendCoach({
    required int gymId,
    required int coachId,
    required String token,
  }) async {
    try {
      final online = await ConnectivityHelper.isOnline();
      if(!online){
        errorMessage = 'You are offline. Please try again when you\'re connected.';
        notifyListeners();
        return false;
      }
      await _repo.suspendCoach(gymId, coachId, token);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<String?> unsuspendCoach({
    required int gymId,
    required int coachId,
    required String token,
  }) async {
    try {
      final online = await ConnectivityHelper.isOnline();
      if(!online){
        errorMessage = 'You are offline. Please try again when you\'re connected.';
        notifyListeners();
        return null;
    }
      await _repo.unsuspendCoach(gymId, coachId, token);
      return null; // success
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('expired')) {
        return 'Membership is expired — please renew first';
      }
      return 'Error: $msg';
    }
  }

  void setFilter(String filter) {
    selectedFilter = filter;
    notifyListeners();
  }

  void setSearch(String query) {
    searchQuery = query;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}