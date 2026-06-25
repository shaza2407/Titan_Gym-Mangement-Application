class AnalyticsSummary{
  final double totalRevenue, revenueChange;
  final String revenueMonth;
  final int activeMembers, newMembersThisMonth, avgDailyAttendance;
  final double avgAttendanceChange;
  final int activeClasses, newClassesThisMonth;

  const AnalyticsSummary({
    required this.totalRevenue,
    required this.revenueChange,
    required this.revenueMonth,
    required this.activeMembers,
    required this.newMembersThisMonth,
    required this.avgDailyAttendance,
    required this.avgAttendanceChange,
    required this.activeClasses,
    required this.newClassesThisMonth,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> j) => AnalyticsSummary(
    totalRevenue: (j['total_revenue'] as num).toDouble(),
    revenueChange: (j['revenue_change'] as num).toDouble(),
    revenueMonth: j['revenue_month'] as String,
    activeMembers: j['active_members'] as int,
    newMembersThisMonth: j['new_members_this_month'] as int,
    avgDailyAttendance: j['avg_daily_attendance'] as int,
    avgAttendanceChange: (j['avg_attendance_change'] as num).toDouble(),
    activeClasses: j['active_classes'] as int,
    newClassesThisMonth: j['new_classes_this_month'] as int,
  );
}


class MonthRevenue {
  final String month;
  final double revenue;

  const MonthRevenue({required this.month, required this.revenue});
  factory MonthRevenue.fromJson(Map<String, dynamic> j) => MonthRevenue(month: j['month'] as String, revenue: (j['revenue'] as num).toDouble(),);
}

class MonthMembers {
  final String month;
  final int totalMembers;

  const MonthMembers({required this.month, required this.totalMembers});
  factory MonthMembers.fromJson(Map<String, dynamic> j) => MonthMembers(month: j['month'] as String, totalMembers: j['total_members'] as int,);
}

class MembershipTypeCount {
  final String type;
  final int count;

  const MembershipTypeCount({required this.type, required this.count});
  factory MembershipTypeCount.fromJson(Map<String, dynamic> j) => MembershipTypeCount(type: j['type'] as String, count: j['count'] as int,);
}

class DayPattern {
  final String day;
  final int morning, evening;

  const DayPattern({required this.day, required this.morning, required this.evening});
  factory DayPattern.fromJson(Map<String, dynamic> j) => DayPattern(day: j['day'] as String, morning: j['morning'] as int, evening: j['evening'] as int,);
}