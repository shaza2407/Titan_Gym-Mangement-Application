import 'package:flutter/material.dart';
import '../../data/attendance_repository.dart';
import '../../domain/attendance_model.dart';

class ClientScanController extends ChangeNotifier {
  final AttendanceRepository _repo = AttendanceRepository();

  bool isLoading = false;
  bool isCheckingIn = false;
  bool checkedInNow = false;
  bool isOfflineStatus =
      false; // true => status is from cache, not verified live
  String? errorMessage;

  CheckinStatusModel? status;
  List<AttendanceModel> recentCheckins = [];

  Future<void> loadStatus(String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    bool statusOk = true;
    try {
      final result = await _repo.getCheckinStatus(token);
      status = result.status;
      isOfflineStatus = !result.isLive;
    } catch (e) {
      statusOk = false;
    }

    try {
      recentCheckins = await _repo.getRecentCheckins(token);
    } catch (e) {
      // history failing isn't fatal
    }

    if (!statusOk && status == null) {
      errorMessage =
          'Unable to load check-in status. Check your connection and try again.';
    } else if (isOfflineStatus) {
      errorMessage = "You're offline — reconnect to check in.";
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> doCheckin(String token, String qrCode) async {
    isCheckingIn = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _repo.getCheckinStatus(token);
      status = result.status;
      isOfflineStatus = !result.isLive;

      if (isOfflineStatus) {
        errorMessage = "You're offline — reconnect to check in.";
        return false;
      }
      if (!status!.canCheckin) {
        errorMessage = 'Your status changed — please review and try again.';
        return false;
      }

      await _repo.doCheckin(token, qrCode);
      checkedInNow = true;
      await loadStatus(token);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isCheckingIn = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> get statusInfo {
    if (isOfflineStatus) {
      return {
        'message': "Offline — showing last known status",
        'color': Colors.grey,
      };
    }
    switch (status?.reason) {
      case 'ok':
        return {
          'message': 'Ready to check in',
          'color': const Color(0xFF4CAF50),
        };
      case 'already_checked_in':
        return {
          'message': 'Already checked in today',
          'color': const Color(0xFF4F46E5),
        };
      case 'expired':
        return {
          'message': 'Subscription expired — please renew',
          'color': Colors.red,
        };
      case 'suspended':
        return {
          'message': 'Membership suspended — contact gym',
          'color': Colors.red,
        };
      case 'not_connected':
        return {'message': 'Not connected to any gym', 'color': Colors.grey};
      default:
        if (isLoading) return {'message': 'Loading...', 'color': Colors.grey};
        return {'message': 'Unable to load status', 'color': Colors.grey};
    }
  }

  // Button is only enabled when status is live AND the server says canCheckin.
  bool get canCheckin => !isOfflineStatus && (status?.canCheckin ?? false);
  bool get isBlocked =>
      status?.reason == 'expired' || status?.reason == 'suspended';
}
