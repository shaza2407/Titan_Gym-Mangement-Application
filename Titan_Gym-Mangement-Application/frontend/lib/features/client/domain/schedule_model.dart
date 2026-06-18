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
      id: json['id'],
      title: json['title'],
      coachName: json['coach_name'],
      dayOfWeek: json['day_of_week'],
      date: json['date'],
      startTime: json['start_time'],
      duration: json['duration'],
      isRecurring: json['is_recurring'],
      currentClients: json['current_clients'],
      maxClients: json['max_clients'],
      isEnrolled: json['is_enrolled'] ?? false,
      isFull: json['is_full'] ?? false,
      nextDate: json['next_date'],
    );
  }
}

class ScheduleStatsModel {
  final int enrolled;
  final int classesThisMonth; // ← rename
  final int minutesWeek;

  ScheduleStatsModel({
    required this.enrolled,
    required this.classesThisMonth,
    required this.minutesWeek,
  });

  factory ScheduleStatsModel.fromJson(Map<String, dynamic> json) {
    return ScheduleStatsModel(
      enrolled: json['enrolled'],
      classesThisMonth: json['upcoming'], // ← backend still sends 'upcoming'
      minutesWeek: json['minutes_week'],
    );
  }
}

class WeeklyClassItem {
  final int id;
  final String title;
  final String startTime;
  final int duration;
  final String? coachName;

  WeeklyClassItem({
    required this.id,
    required this.title,
    required this.startTime,
    required this.duration,
    this.coachName,
  });

  factory WeeklyClassItem.fromJson(Map<String, dynamic> json) {
    return WeeklyClassItem(
      id: json['id'],
      title: json['title'],
      startTime: json['start_time'],
      duration: json['duration'],
      coachName: json['coach_name'],
    );
  }
}

class WeeklyDayModel {
  final String day;
  final String label;
  final List<WeeklyClassItem> classes; // ← changed from ClassModel

  WeeklyDayModel({
    required this.day,
    required this.label,
    required this.classes,
  });

  factory WeeklyDayModel.fromJson(Map<String, dynamic> json) {
    return WeeklyDayModel(
      day: json['day'],
      label: json['label'] ?? json['day'],
      classes: (json['classes'] as List)
          .map((e) => WeeklyClassItem.fromJson(e)) // ← changed
          .toList(),
    );
  }
}
