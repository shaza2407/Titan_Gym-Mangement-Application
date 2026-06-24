class SignUpRequest {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final String password;

  SignUpRequest({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'name':     fullName,
        'email':    email,
        'phone':    phoneNumber,
        'password': password,
        'role':     role,
      };
}

class VerifyEmailRequest {
  final String email;
  final String code;

  VerifyEmailRequest({required this.email, required this.code});

  Map<String, dynamic> toJson() => {'email': email, 'code': code};
}

class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class ResetPasswordRequest {
  final String email;
  final String code;
  final String newPassword;

  ResetPasswordRequest({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'email':        email,
        'code':         code,
        'new_password': newPassword,
      };
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class LoginResponse {
  final String accessToken;
  final String role;
  final int userId;

  LoginResponse({
    required this.accessToken,
    required this.role,
    required this.userId,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: json['access_token'] as String,
        role:        json['role'] as String,
        userId:      json['userID'] is int
            ? json['userID'] as int
            : int.parse(json['userID'].toString()),
      );
}

class ClientProfileResponse {
  final bool isConnected;

  ClientProfileResponse({required this.isConnected});

  factory ClientProfileResponse.fromJson(Map<String, dynamic> json) =>
      ClientProfileResponse(isConnected: json['is_connected'] as bool);
}