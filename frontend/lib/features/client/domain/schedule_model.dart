// lib/features/client/domain/schedule_model.dart

class ClassModel {
  final int id;
  final String title;
  final String? coachName;
  final String? dayOfWeek;
  final String? date;
  final String startTime;
  final int duration;
  final bool isRecurring;
  final int currentClients;
  final int maxClients;
  final bool isEnrolled;
  final bool isFull;
  final String? nextDate;

  ClassModel({
    required this.id,
    required this.title,
    this.coachName,
    this.dayOfWeek,
    this.date,
    required this.startTime,
    required this.duration,
    required this.isRecurring,
    required this.currentClients,
    required this.maxClients,
    required this.isEnrolled,
    required this.isFull,
    this.nextDate,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id:             json['id'],
      title:          json['title'],
      coachName:      json['coach_name'],
      dayOfWeek:      json['day_of_week'],
      date:           json['date'],
      startTime:      json['start_time'],
      duration:       json['duration'],
      isRecurring:    json['is_recurring'],
      currentClients: json['current_clients'],
      maxClients:     json['max_clients'],
      isEnrolled:     json['is_enrolled'] ?? false,
      isFull:         json['is_full'] ?? false,
      nextDate:       json['next_date'],
    );
  }
}

class ScheduleStatsModel {
  final int enrolled;
  final int upcoming;
  final int minutesWeek;

  ScheduleStatsModel({
    required this.enrolled,
    required this.upcoming,
    required this.minutesWeek,
  });

  factory ScheduleStatsModel.fromJson(Map<String, dynamic> json) {
    return ScheduleStatsModel(
      enrolled:     json['enrolled'],
      upcoming:     json['upcoming'],
      minutesWeek:  json['minutes_week'],
    );
  }
}

class WeeklyDayModel {
  final String day;
  final List<ClassModel> classes;

  WeeklyDayModel({required this.day, required this.classes});

  factory WeeklyDayModel.fromJson(Map<String, dynamic> json) {
    return WeeklyDayModel(
      day:     json['day'],
      classes: (json['classes'] as List)
          .map((e) => ClassModel.fromJson(e))
          .toList(),
    );
  }
}