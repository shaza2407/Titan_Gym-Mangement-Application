
class AttendanceModel {
  final int id;
  final DateTime checkedIn;

  AttendanceModel({required this.id, required this.checkedIn});

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id:        json['id'],
      checkedIn: DateTime.parse(json['checked_in']).toLocal(),
    );
  }
}

class CheckinStatusModel {
  final bool canCheckin;
  final String reason;
  final int? membershipID;
  final String? subscription;
  final String? subscriptionEnd;
  final String? status;

  CheckinStatusModel({
    required this.canCheckin,
    required this.reason,
    this.membershipID,
    this.subscription,
    this.subscriptionEnd,
    this.status,
  });

  factory CheckinStatusModel.fromJson(Map<String, dynamic> json) {
    return CheckinStatusModel(
      canCheckin:      json['can_checkin'],
      reason:          json['reason'],
      membershipID:    json['membershipID'],
      subscription:    json['subscription'],
      subscriptionEnd: json['subscription_end'],
      status:          json['status'],
    );
  }
}