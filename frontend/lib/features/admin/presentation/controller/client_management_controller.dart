import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';
import '../../domain/client_model.dart';

class ClientManagementController extends ChangeNotifier {
  final AdminRepository _repo = AdminRepository();

  ClientListResponse? data;
  bool isLoading  = false;
  String? errorMessage;
  String selectedFilter = 'all';
  String searchQuery    = '';

  final searchController = TextEditingController();

  List<ClientListItem> get filtered {
    const statusOrder = {
      'active': 0, 'pending': 1, 'expired': 2, 'suspended': 3
    };
    final members = data?.members ?? [];
    return members.where((m) {
      final matchFilter = selectedFilter == 'all' || m.status == selectedFilter;
      final matchSearch = searchQuery.isEmpty ||
          m.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          m.email.toLowerCase().contains(searchQuery.toLowerCase());
      return matchFilter && matchSearch;
    }).toList()
      ..sort((a, b) =>
          (statusOrder[a.status] ?? 99).compareTo(statusOrder[b.status] ?? 99));
  }

  Future<void> loadClients({
    required int gymId,
    required String token,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      data = await _repo.fetchClients(gymId, token);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> suspendClient({
    required int gymId,
    required int memberId,
    required String token,
  }) async {
    try {
      await _repo.suspendClient(gymId, memberId, token);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<String?> unsuspendClient({
    required int gymId,
    required int memberId,
    required String token,
  }) async {
    try {
      await _repo.unsuspendClient(gymId, memberId, token);
      return null; // success
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('expired')) {
        return 'Membership is expired — please renew first';
      } else if (msg.contains('active membership at another gym')) {
        return 'Client is now active at another gym — send a new invitation to re-add them';
      }
      return 'Error: $msg';
    }
  }

  Future<bool> cancelInvitation({
    required int gymId,
    required String email,
    required String token,
  }) async {
    try {
      await _repo.cancelInvitation(gymId, email, token);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
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