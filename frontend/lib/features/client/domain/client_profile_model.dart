// lib/features/client/domain/client_profile_model.dart

class ClientProfileModel {
  final int userID;
  final int clientID;
  final String name;
  final String email;
  final String? phone;
  final int? age;           // calculated, read-only
  final String? dateOfBirth; // editable
  final String? gender;
  final String? fitnessGoal;
  final String? bio;
  final String? emergencyContact;

  ClientProfileModel({
    required this.userID,
    required this.clientID,
    required this.name,
    required this.email,
    this.phone,
    this.age,
    this.dateOfBirth,
    this.gender,
    this.fitnessGoal,
    this.bio,
    this.emergencyContact,
  });

  factory ClientProfileModel.fromJson(Map<String, dynamic> json) {
    return ClientProfileModel(
      userID:           json['userID'],
      clientID:         json['clientID'],
      name:             json['name'],
      email:            json['email'],
      phone:            json['phone'],
      age:              json['age'],
      dateOfBirth:      json['date_of_birth'],
      gender:           json['gender'],
      fitnessGoal:      json['fitness_goal'],
      bio:              json['bio'],
      emergencyContact: json['emergency_contact'],
    );
  }
}