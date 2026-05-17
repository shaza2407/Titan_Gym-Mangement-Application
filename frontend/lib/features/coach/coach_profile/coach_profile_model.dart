class CoachProfileModel {
  final int userID;
  final int coachID;
  final String name;
  final String email;
  final String? phone;
  final int? age;
  final String? gender;
  final String? fitnessGoal;
  final String? bio;
  final String? emergencyContact;
  final String? profilePicture;

  CoachProfileModel({
    required this.userID,
    required this.coachID,
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

  factory CoachProfileModel.fromJson(Map<String, dynamic> json) {
    return CoachProfileModel(
      userID:           json['userID'],
      coachID:          json['coachID'],
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