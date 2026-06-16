class CoachProfileModel {
  final int userID;
  final int coachID;
  final String name;
  final String email;
  final String? phone;
  final String? bio;
  final List<String>? specializations;
  final String? certifications;
  final int? yearsExperience;
  final String? dateOfBirth;

  CoachProfileModel({
    required this.userID,
    required this.coachID,
    required this.name,
    required this.email,
    this.phone,
    this.bio,
    this.specializations,
    this.certifications,
    this.yearsExperience,
    this.dateOfBirth,
  });

  factory CoachProfileModel.fromJson(Map<String, dynamic> json) {
    return CoachProfileModel(
      userID:          json['userID'],
      coachID:         json['coachID'],
      name:            json['name'],
      email:           json['email'],
      phone:           json['phone'],
      bio:             json['bio'],
      specializations: json['specializations'] != null
          ? List<String>.from(json['specializations'])
          : null,
      certifications:  json['certifications'],
      yearsExperience: json['years_experience'],
      dateOfBirth:     json['date_of_birth'],
    );
  }
}