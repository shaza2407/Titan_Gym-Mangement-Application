class ClientProfileModel {
  final int userID;
  final int clientID;
  final String name;
  final String email;
  final String? phone;
  final int? age;
  final String? gender;
  final String? fitnessGoal;
  final String? bio;
  final String? emergencyContact;
  final String? profilePicture;

  ClientProfileModel({
    required this.userID,
    required this.clientID,
    required this.name,
    required this.email,
    this.phone,
    this.age,
    this.gender,
    this.fitnessGoal,
    this.bio,
    this.emergencyContact,
    this.profilePicture,
  });

  factory ClientProfileModel.fromJson(Map<String, dynamic> json) {
    return ClientProfileModel(
      userID:           json['userID'],
      clientID:         json['clientID'],
      name:             json['name'],
      email:            json['email'],
      phone:            json['phone'],
      age:              json['age'],
      gender:           json['gender'],
      fitnessGoal:      json['fitness_goal'],
      bio:              json['bio'],
      emergencyContact: json['emergency_contact'],
      profilePicture:   json['profile_picture'],
    );
  }
}