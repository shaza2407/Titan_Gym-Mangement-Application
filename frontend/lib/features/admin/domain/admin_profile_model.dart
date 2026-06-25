class AdminProfile {
  final int adminID;
  final int userID;
  final String name;
  final String email;
  final String? phone;
  final String? createdAt;
  final int totalGyms;

  AdminProfile({
    required this.adminID,
    required this.userID,
    required this.name,
    required this.email,
    this.phone,
    this.createdAt,
    this.totalGyms = 0,
  });

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      adminID:   (json['adminID']    as int?)    ?? 0,
      userID:    (json['userID']     as int?)    ?? 0,
      name:      (json['name']       as String?) ?? '',
      email:     (json['email']      as String?) ?? '',
      phone:      json['phone']      as String?,
      createdAt:  json['created_at'] as String?,
      totalGyms: (json['total_gyms'] as int?)    ?? 0,
    );
  }
}