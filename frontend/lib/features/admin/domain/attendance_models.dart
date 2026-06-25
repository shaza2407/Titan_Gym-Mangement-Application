class AttendanceStats {
  final int totalToday, thisWeek;

  AttendanceStats({
    required this.totalToday,
    required this.thisWeek,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> j) => AttendanceStats(
    totalToday: j['today_total'] as int,
    thisWeek: j['this_week'] as int,
  );
}

class QRCodeInfo {
  final int gymId;
  final String qrIdentifier, gymName;

  const QRCodeInfo({
    required this.gymId,
    required this.qrIdentifier,
    required this.gymName,
  });

  factory QRCodeInfo.fromJson(Map<String, dynamic> j) => QRCodeInfo(
    gymId: j['gym_id'] as int,
    qrIdentifier: j['qr_identifier'] as String,
    gymName: j['gym_name'] as String,
  );
}

class DayAttendance {
  final String day;
  final int count;

  const DayAttendance({required this.day, required this.count});

  factory DayAttendance.fromJson(Map<String, dynamic> j) =>
      DayAttendance(day: j['day'] as String, count: j['count'] as int);
}

class WeeklyAttendance {
  final String weekStart;
  final List<DayAttendance> days;

  const WeeklyAttendance({required this.weekStart, required this.days});

  factory WeeklyAttendance.fromJson(Map<String, dynamic> j) => WeeklyAttendance(
    weekStart: j['week_start'] as String,
    days: (j['days'] as List).map((e) => DayAttendance.fromJson(e)).toList()
  );
}

