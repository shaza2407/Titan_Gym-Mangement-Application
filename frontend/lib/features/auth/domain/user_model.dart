class UserModel {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final String token;

  UserModel({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      fullName: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      role: json['role'],
      token: json['access_token'],
    );
  }
}