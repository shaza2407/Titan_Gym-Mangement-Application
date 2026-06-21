class GymInfoModel {
  final int gymID;
  final String gymName;
  final String location;
  final String gymType;
  final String openingHours;
  final String closingHours;
  final String? qrCode;

  GymInfoModel({
    required this.gymID,
    required this.gymName,
    required this.location,
    required this.gymType,
    required this.openingHours,
    required this.closingHours,
    this.qrCode,
  });

  factory GymInfoModel.fromJson(Map<String, dynamic> j) => GymInfoModel(
        gymID: j['gymID'],
        gymName: j['gymName'],
        location: j['location'],
        gymType: j['gymType'],
        openingHours: j['openingHours'],
        closingHours: j['closingHours'],
        qrCode: j['QRCode'],
      );
}

class AnnouncementModel {
  final int announceId;
  final String title;
  final String content;
  final String reciever;
  final DateTime createdAt;

  AnnouncementModel({
    required this.announceId,
    required this.title,
    required this.content,
    required this.reciever,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> j) => AnnouncementModel(
        announceId: j['announce_id'],
        title: j['title'],
        content: j['content'],
        reciever: j['reciever'],
        createdAt: DateTime.parse(j['created_at']),
      );
}

class GymClassModel {
  final int id;
  final String title;
  final String dayOfWeek;
  final String? date;
  final String startTime;
  final int duration;
  final bool isRecurring;
  final String? coachName;
  final int currentClients;
  final int maxClients;

  GymClassModel({
    required this.id,
    required this.title,
    required this.dayOfWeek,
    this.date,
    required this.startTime,
    required this.duration,
    required this.isRecurring,
    this.coachName,
    required this.currentClients,
    required this.maxClients,
  });

  bool get isFull => currentClients >= maxClients;
  double get fillRatio => maxClients > 0 ? currentClients / maxClients : 0;

  factory GymClassModel.fromJson(Map<String, dynamic> j) => GymClassModel(
        id: j['id'],
        title: j['title'],
        dayOfWeek: j['day_of_week'] ?? '',
        date: j['date']?.toString(),
        startTime: j['start_time'],
        duration: j['duration'],
        isRecurring: j['is_recurring'] ?? true,
        coachName: j['coach_name'],
        currentClients: j['current_clients'] ?? 0,
        maxClients: j['max_clients'] ?? 0,
      );
}