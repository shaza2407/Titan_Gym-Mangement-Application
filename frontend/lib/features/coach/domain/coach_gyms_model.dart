import 'coach_dashboard_model.dart';

class CoachGymModel {
  final int gymId;
  final String gymName;
  final String address;
  final String status;
  final int clientsCount;
  final int classesCount;
  final CoachUpcomingClassModel? nextClass;

  CoachGymModel({
    required this.gymId,
    required this.gymName,
    required this.address,
    required this.status,
    required this.clientsCount,
    required this.classesCount,
    required this.nextClass,
  });

  factory CoachGymModel.fromJson(Map<String, dynamic> json) {
    return CoachGymModel(
      gymId: json['gym_id'] ?? 0,
      gymName: json['name'] ?? 'Unknown Gym',
      address: json['address'] ?? '',
      status: json['status'] ?? 'Suspended',
      clientsCount: json['clients_count'] ?? 0,
      classesCount: json['classes_count'] ?? 0,
      nextClass: json['next_class'] != null
          ? CoachUpcomingClassModel.fromJson(json['next_class'])
          : null,
    );
  }
}

class CoachAnnouncementModel {
  final int id;
  final int gymId;
  final String title;
  final String gymName;
  final String date;
  final String content;

  CoachAnnouncementModel({
    required this.id,
    required this.gymId,
    required this.title,
    required this.gymName,
    required this.date,
    required this.content,
  });

  factory CoachAnnouncementModel.fromJson(Map<String, dynamic> json) {
    return CoachAnnouncementModel(
      id: json['id'] ?? 0,
      gymId: json['gym_id'] ?? 0,
      title: json['title'] ?? 'No Title',
      gymName: json['gym_name'] ?? 'Unknown Gym',
      date: json['created_at']?.toString() ?? 'Unknown Date',
      content: json['content'] ?? '',
    );
  }
}
