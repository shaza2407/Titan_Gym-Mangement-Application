class AdminScheduleStatsModel {
  final int totalClasses;
  final int totalEnrolled;
  final int totalCoaches;
  final int pendingRequests;

  AdminScheduleStatsModel({
    required this.totalClasses,
    required this.totalEnrolled,
    required this.totalCoaches,
    required this.pendingRequests,
  });

  factory AdminScheduleStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminScheduleStatsModel(
      totalClasses:    json['total_classes'] ?? 0,
      totalEnrolled:   json['total_enrolled'] ?? 0,
      totalCoaches:    json['total_coaches'] ?? 0,
      pendingRequests: json['pending_requests'] ?? 0,
    );
  }
}

class ClassSessionModel {
  final int id;
  final String title;
  final String? dayOfWeek;
  final String? date;
  final String startTime;
  final int duration;
  final bool isRecurring;
  final int gymID;
  final int coachId;
  final String? coachName;
  final int currentClients;
  final int maxClients;

  ClassSessionModel({
    required this.id,
    required this.title,
    this.dayOfWeek,
    this.date,
    required this.startTime,
    required this.duration,
    required this.isRecurring,
    required this.gymID,
    required this.coachId,
    this.coachName,
    required this.currentClients,
    required this.maxClients,
  });

  factory ClassSessionModel.fromJson(Map<String, dynamic> json) {
    return ClassSessionModel(
      id:             json['id'],
      title:          json['title'],
      dayOfWeek:      json['day_of_week'] as String?,
      date:           json['date'],
      startTime:      json['start_time'],
      duration:       json['duration'],
      isRecurring:    json['is_recurring'] ?? false,
      gymID:          json['gymID'],
      coachId:        json['coach_id'],
      coachName:      json['coach_name'],
      currentClients: json['current_clients'] ?? 0,
      maxClients:     json['max_clients'] ?? 0,
    );
  }

  bool get isFull => currentClients >= maxClients;
  double get fillRatio => maxClients == 0 ? 0 : currentClients / maxClients;
}

class ClassRequestModel {
  final int id;
  final int coachId;
  final String? coachName;
  final int gymID;
  final String className;
  final bool isRecurring;
  final String? dayOfWeek;
  final String? requestedDate;
  final String requestedTime;
  final int duration;
  final int maxCapacity;
  final String? reasonForRequest;
  final String status;
  final String createdAt;

  ClassRequestModel({
    required this.id,
    required this.coachId,
    this.coachName,
    required this.gymID,
    required this.className,
    required this.isRecurring,
    this.dayOfWeek,
    this.requestedDate,
    required this.requestedTime,
    required this.duration,
    required this.maxCapacity,
    this.reasonForRequest,
    required this.status,
    required this.createdAt,
  });

  factory ClassRequestModel.fromJson(Map<String, dynamic> json) {
    return ClassRequestModel(
      id:               json['id'],
      coachId:          json['coach_id'],
      coachName:        json['coach_name'],
      gymID:            json['gymID'],
      className:        json['class_name'],
      isRecurring:      json['is_recurring'] ?? false,
      dayOfWeek:        json['day_of_week'],
      requestedDate:    json['requested_date'],
      requestedTime:    json['requested_time'],
      duration:         json['duration'],
      maxCapacity:      json['max_capacity'],
      reasonForRequest: json['reason_for_request'],
      status:           json['status'],
      createdAt:        json['created_at']?.toString() ?? '',
    );
  }
}

class ClassMemberModel {
  final int clientID;
  final String name;
  final String email;
  final String? phone;
  final String classDate;
  final String enrolledAt;

  ClassMemberModel({
    required this.clientID,
    required this.name,
    required this.email,
    this.phone,
    required this.classDate,
    required this.enrolledAt,
  });

  factory ClassMemberModel.fromJson(Map<String, dynamic> json) {
    return ClassMemberModel(
      clientID:   json['clientID'],
      name:       json['name'],
      email:      json['email'],
      phone:      json['phone'],
      classDate:  json['class_date'],
      enrolledAt: json['enrolled_at']?.toString() ?? '',
    );
  }
}

class CoachOptionModel {
  final int coachId;
  final String name;

  CoachOptionModel({required this.coachId, required this.name});

  factory CoachOptionModel.fromJson(Map<String, dynamic> json) {
    return CoachOptionModel(
      coachId: json['coach_id'],
      name:    json['name'],
    );
  }
}