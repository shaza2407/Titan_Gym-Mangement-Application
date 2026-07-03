import 'package:flutter/foundation.dart';
import '../../data/attendance_repository.dart';
import '../../domain/attendance_models.dart';

class AttendanceController extends ChangeNotifier {
  final AttendanceRepository _repo;

  AttendanceController({required String token, required int gymId})
      : _repo = AttendanceRepository(token: token, gymId: gymId);

  AttendanceStats? stats;
  QRCodeInfo?      qrInfo;
  WeeklyAttendance? weeklyAttendance;
  bool   isLoading = false;
  String? error;

  Future<void> load() async {
  isLoading = true;
  error = null;
  notifyListeners();

  try {
    // Stats and weekly can load from cache offline
    final results = await Future.wait([
      _repo.fetchStats(),
      _repo.fetchWeeklyAttendance(),
    ]);
    stats            = results[0] as AttendanceStats;
    weeklyAttendance = results[1] as WeeklyAttendance;
  } catch (e) {
    error = e.toString();
  }

  // QR is independent - failure doesn't break the rest
  try {
    qrInfo = await _repo.fetchQRCode();
  } catch (_) {
    qrInfo = null; // handled in UI
  }

  isLoading = false;
  notifyListeners();
}
}