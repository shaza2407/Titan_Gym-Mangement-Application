class CoachScheduleStatsModel {
  final int weeklyClasses;
  final int totalStudents;
  final int pendingRequests;

  CoachScheduleStatsModel({
    required this.weeklyClasses,
    required this.totalStudents,
    required this.pendingRequests,
  });

  factory CoachScheduleStatsModel.fromJson(Map<String, dynamic> json) {
    return CoachScheduleStatsModel(
      weeklyClasses: json['weekly_classes'],
      totalStudents: json['total_students'],
      pendingRequests: json['pending_requests'],
    );
  }
}

class CoachClassModel {
  final int id;
  final String title;
  final String? dayOfWeek;
  final String? date;
  final String startTime;
  final int duration;
  final bool isRecurring;
  final String? gymName;
  final int currentClients;
  final int maxClients;

  CoachClassModel({
    required this.id,
    required this.title,
    this.dayOfWeek,
    this.date,
    required this.startTime,
    required this.duration,
    required this.isRecurring,
    this.gymName,
    required this.currentClients,
    required this.maxClients,
  });

  factory CoachClassModel.fromJson(Map<String, dynamic> json) {
    return CoachClassModel(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? 'Untitled Class',
      dayOfWeek: json['day_of_week']?.toString(),
      date: json['date']?.toString(),
      startTime: json['start_time']?.toString() ?? '00:00',
      duration: json['duration']?? 45,
      isRecurring: json['is_recurring']?? false,
      gymName: json['gym_name']?.toString(),
      currentClients: json['current_clients']?? 0,
      maxClients: json['max_clients']?? 0,
    );
  }
}

class CoachWeeklyDayModel {
  final String day;
  final String label;
  final List<CoachWeeklyClassItem> classes;

  CoachWeeklyDayModel({
    required this.day,
    required this.label,
    required this.classes,
  });

  factory CoachWeeklyDayModel.fromJson(Map<String, dynamic> json) {
    return CoachWeeklyDayModel(
      day: json['day'],
      label: json['label'] ?? json['day'],
      classes: (json['classes'] as List)
          .map((e) => CoachWeeklyClassItem.fromJson(e))
          .toList(),
    );
  }
}

class CoachWeeklyClassItem {
  final int id;
  final String title;
  final String startTime;
  final int duration;
  final String? gymName;
  final int currentClients;
  final int maxClients;

  CoachWeeklyClassItem({
    required this.id,
    required this.title,
    required this.startTime,
    required this.duration,
    this.gymName,
    required this.currentClients,
    required this.maxClients,
  });

  factory CoachWeeklyClassItem.fromJson(Map<String, dynamic> json) {
    return CoachWeeklyClassItem(
      id: json['id'],
      title: json['title'],
      startTime: json['start_time'],
      duration: json['duration'],
      gymName: json['gym_name'],
      currentClients: json['current_clients'],
      maxClients: json['max_clients'],
    );
  }
}

class CoachClassRequestModel {
  final int id;
  final int coachId;
  final int gymID;
  final String className;
  final bool isRecurring;
  final String? dayOfWeek;
  final String? requestedDate;
  final String requestedTime;
  final int duration;
  final int maxCapacity;
  final String? reason;
  final String status;
  final String createdAt;

  CoachClassRequestModel({
    required this.id,
    required this.coachId,
    required this.gymID,
    required this.className,
    required this.isRecurring,
    this.dayOfWeek,
    this.requestedDate,
    required this.requestedTime,
    required this.duration,
    required this.maxCapacity,
    this.reason,
    required this.status,
    required this.createdAt,
  });

  factory CoachClassRequestModel.fromJson(Map<String, dynamic> json) {
    return CoachClassRequestModel(
      id: json['id'] ?? 0,
      coachId: json['coach_id'] ?? 0,
      gymID: json['gymID'] ?? 0,
      className: json['class_name']?.toString() ?? 'Untitled',
      isRecurring: json['is_recurring'] ?? false,
      dayOfWeek: json['day_of_week']?.toString(),
      requestedDate: json['requested_date']?.toString(),
      requestedTime: json['requested_time']?.toString() ?? '',
      duration: json['duration'] ?? 45,
      maxCapacity: json['max_capacity'] ?? 20,
      reason: json['reason_for_request']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString() ?? '',    );
  }
}

class CoachGymLookupModel {
  final int id;
  final String name;

  CoachGymLookupModel({
    required this.id,
    required this.name,
  });

  factory CoachGymLookupModel.fromJson(Map<String, dynamic> json){
    return CoachGymLookupModel(
      id: json['id'],
      name: json['name'] ?? 'Unknown Gym Branch',
    );
  }
}
