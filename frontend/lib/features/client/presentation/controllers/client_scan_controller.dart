import 'package:flutter/material.dart';
import '../../data/attendance_repository.dart';
import '../../domain/attendance_model.dart';

class ClientScanController extends ChangeNotifier {
  final AttendanceRepository _repo = AttendanceRepository();

  bool isLoading       = false;
  bool isCheckingIn    = false;
  bool checkedInNow    = false;
  String? errorMessage;

  CheckinStatusModel? status;
  List<AttendanceModel> recentCheckins = [];

  Future<void> loadStatus(String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      status         = await _repo.getCheckinStatus(token);
      recentCheckins = await _repo.getRecentCheckins(token);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> doCheckin(String token) async {
    isCheckingIn = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repo.doCheckin(token);
      checkedInNow = true;
      await loadStatus(token); // refresh everything
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isCheckingIn = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> get statusInfo {
    switch (status?.reason) {
      case 'ok':
        return {'message': 'Ready to check in',                    'color': const Color(0xFF4CAF50)};
      case 'already_checked_in':
        return {'message': 'Already checked in today',             'color': const Color(0xFF4F46E5)};
      case 'expired':
        return {'message': 'Subscription expired — please renew',  'color': Colors.red};
      case 'suspended':
        return {'message': 'Membership suspended — contact gym',   'color': Colors.red};
      case 'not_connected':
        return {'message': 'Not connected to any gym',             'color': Colors.grey};
      default:
        return {'message': 'Loading...',                           'color': Colors.grey};
    }
  }

  bool get canCheckin  => status?.canCheckin ?? false;
  bool get isBlocked   => status?.reason == 'expired' || status?.reason == 'suspended';
}