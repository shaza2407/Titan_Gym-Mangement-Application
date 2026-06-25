
class MachineModel {
  final int inventoryID;
  final String machineName;
  final String machineType;
  final int quantity;

  MachineModel({
    required this.inventoryID,
    required this.machineName,
    required this.machineType,
    required this.quantity,
  });

  factory MachineModel.fromJson(Map<String, dynamic> json) {
    return MachineModel(
      inventoryID: json['inventoryID'] ?? 0,
      machineName: json['machineName'] ?? '',
      machineType: json['machineType'] ?? 'Cardio',
      quantity:    json['quantity']    ?? 1,
    );
  }
}

class GymModel {
  final int gymID;
  final int adminID;
  final String gymName;
  final String location;
  final String qrCode;
  final String gymType;
  final String openingHours;
  final String closingHours;
  final List<MachineModel> machines;

  GymModel({
    required this.gymID,
    required this.adminID,
    required this.gymName,
    required this.location,
    required this.qrCode,
    required this.gymType,
    required this.openingHours,
    required this.closingHours,
    this.machines = const [], 
  });

  factory GymModel.fromJson(Map<String, dynamic> json) {
    return GymModel(
      gymID:        json['gymID'],
      adminID:      json['adminID'],
      gymName:      json['gymName'],
      location:     json['location'],
      qrCode:       json['QRCode'] ?? '',
      gymType:      json['gymType'],
      openingHours: json['openingHours'],
      closingHours: json['closingHours'],
      machines: (json['machine_inventory'] as List<dynamic>? ?? []) 
        .map((m) => MachineModel.fromJson(m))
        .toList(),
  )   ;
      
  }
}


class GymDashboardStats {
  final int gymID;
  final String gymName;
  final int totalMembers;
  final int activeSubscriptions;
  final int todayAttendance;
  final int totalClasses;

  GymDashboardStats({
    required this.gymID,
    required this.gymName,
    required this.totalMembers,
    required this.activeSubscriptions,
    required this.todayAttendance,
    required this.totalClasses,
  });

  factory GymDashboardStats.fromJson(Map<String, dynamic> json) {
    return GymDashboardStats(
      gymID:               (json['gymID']               as int?)    ?? 0,
      gymName:             (json['gymName']              as String?) ?? '',
      totalMembers:        (json['totalMembers']         as int?)    ?? 0,
      activeSubscriptions: (json['activeSubscriptions']  as int?)    ?? 0,
      todayAttendance:     (json['todayAttendance']      as int?)    ?? 0,
      totalClasses:        (json['totalClasses']         as int?)    ?? 0,
    );
  }
}

class MachineInput {
  String machineName;
  String machineType;
  int quantity;

  MachineInput({
    this.machineName = '',
    this.machineType = 'Cardio',
    this.quantity = 1,
  });
}