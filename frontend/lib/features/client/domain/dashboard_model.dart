class DashboardStatsModel {
  final int totalVisits;
  final int daysThisWeek;
  final int currentStreak;
  final String? subscription;
  final String? subscriptionEnd;
  final int? daysRemaining;
  final String? membershipStatus;
  final String? gymName;

  DashboardStatsModel({
    required this.totalVisits,
    required this.daysThisWeek,
    required this.currentStreak,
    this.subscription,
    this.subscriptionEnd,
    this.daysRemaining,
    this.membershipStatus,
    this.gymName,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalVisits:      json['total_visits'],
      daysThisWeek:     json['days_this_week'],
      currentStreak:    json['current_streak'],
      subscription:     json['subscription'],
      subscriptionEnd:  json['subscription_end'],
      daysRemaining:    json['days_remaining'],
      membershipStatus: json['membership_status'],
      gymName:          json['gym_name'],
    );
  }

  bool get isExpired   => (daysRemaining ?? 0) < 0;
  bool get isSuspended => membershipStatus == 'suspended';
  bool get isActive    => !isExpired && !isSuspended;
}