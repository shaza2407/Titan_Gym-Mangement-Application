class CoachDashboardStatsModel {
  final int weeklyClasses;
  final int totalClients;
  final int activeGyms;

  CoachDashboardStatsModel({
    required this.weeklyClasses,
    required this.totalClients,
    required this.activeGyms,
  });

  factory CoachDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return CoachDashboardStatsModel(
      weeklyClasses: json['weekly_classes'],
      totalClients: json['total_clients'],
      activeGyms: json['active_gyms'],
    );
  }
}

class CoachUpcomingClassModel {
  final int id;
  final String title;
  final String? dayOfWeek;
  final String? date;
  final String startTime;
  final int duration;
  final String? gymName;
  final int currentClients;
  final int maxClients;

  CoachUpcomingClassModel({
    required this.id,
    required this.title,
    this.dayOfWeek,
    this.date,
    required this.startTime,
    required this.duration,
    this.gymName,
    required this.currentClients,
    required this.maxClients,
  });

  factory CoachUpcomingClassModel.fromJson(Map<String, dynamic> json) {
    return CoachUpcomingClassModel(
      id: json['id'],
      title: json['title'] ?? '',
      dayOfWeek: json['day_of_week'],
      date: json['date'],
      startTime: json['start_time'],
      duration: json['duration'],
      gymName: json['gym_name'] ?? '',
      currentClients: json['current_clients'],
      maxClients: json['max_clients'],
    );
  }
}
