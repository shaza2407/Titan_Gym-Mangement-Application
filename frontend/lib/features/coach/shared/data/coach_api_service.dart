// hold data classes and functions that talk to backend

import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardStats {
  final int weeklyClasses;
  final int totalClients;
  // final int activeGyms;
  final int pendingRequests;

  DashboardStats({
    required this.weeklyClasses,
    required this.totalClients,
    // required this.activeGyms,
    required this.pendingRequests,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      weeklyClasses: json['weekly_classes'] ?? 0,
      totalClients: json['total_students'] ?? 0,
      // activeGyms: json['active_gyms'] ?? 0,
      pendingRequests: json['pending_requests'] ?? 0,
    );
  }
}

class MyClassOffering {
  final String title, scheduleSummary;
  final int currentStudents,
    // gymId,
   maxStudents;

  MyClassOffering({
    required this.title,
    required this.scheduleSummary,
    required this.currentStudents,
    // required this.gymId,
    required this.maxStudents,
    });

  factory MyClassOffering.fromJson(Map<String, dynamic> json) {
    return MyClassOffering(
      title: json['title'] ?? "Unknown Class",
      scheduleSummary: json['schedule_summary'] ?? "",
      currentStudents: json['current_students'] ?? 0,
      // gymId: json['gym_id'],
      maxStudents: json['max_students'] ?? 0,
    );
  }
}
class ClassSessionModel {
final int id, 
  // gymId, 
  currentClients,
  maxStudents;
  final String date, startTime, title;

  ClassSessionModel({
    required this.id,
    // required this.gymId,
    required this.maxStudents,
    required this.currentClients,
    required this.date,
    required this.startTime,
    required this.title,
  });

  factory ClassSessionModel.fromJson(Map<String, dynamic> json) {
    return ClassSessionModel(
      id: json['id'],
      title: json['title'] ?? "",
      date: json['date'],
      startTime: json['start_time'],      
      // gymId: json['gym_id'],
      currentClients: json['current_students'] ?? 0,
      maxStudents: json['max_students'] ?? 0,
    );
  }

}

class ClassRequestHistory {
  final String actionType, status, className, reason, createdAt, requestedDate, requestedTime;
  // final int gymId;

  ClassRequestHistory({
    required this.actionType,
    required this.status,
    required this.className,
    required this.reason,
    required this.createdAt,
    required this.requestedDate,
    required this.requestedTime,
    // required this.gymId,
  });

  factory ClassRequestHistory.fromJson(Map<String, dynamic> json) {
    return ClassRequestHistory(
      actionType: json['action_type'] ?? "",
      status: json['status'] ?? "",
        className: json['class_name'] ??
          json['class_title'] ??
          json['title'] ??
          json['class_type'] ??
          "Unknown Class",
      reason: json['reason'] ?? "",
      createdAt: json['created_at'] ?? "",
      requestedDate: json['requested_date'] ?? "",
      requestedTime: json['requested_time'] ?? "",
      // gymId: json['gym_id'],
    );
  }
}

class CoachApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  static Future<DashboardStats> fetchDashboardStats(int coachId) async{
    final res = await http.get(Uri.parse('$baseUrl/$coachId/dashboard'));
    if(res.statusCode == 200){
      return DashboardStats.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to load dashboard stats");

  }

  static Future<DashboardStats> fetchScheduleStats(int coachId) async {
    final res = await http.get(Uri.parse('$baseUrl/$coachId/schedule/stats'));
    if(res.statusCode == 200){
      return DashboardStats.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to load dashboard stats");

  }

  static Future<List<ClassSessionModel>> fetchDashboardUpcomingClasses(int coachId) async {
    final res = await http.get(Uri.parse('$baseUrl/$coachId/dashboard/upcoming-classes?limit=3'));
    if(res.statusCode == 200){
      return (jsonDecode(res.body) as List).map((j)=> ClassSessionModel.fromJson(j)).toList();
    }
    throw Exception("Failed to load upcoming classes");
  }
  static Future<List<ClassSessionModel>> fetchWeeklySchedule(int coachId) async {
    final res = await http.get(Uri.parse('$baseUrl/$coachId/schedule/this-week'));
    if(res.statusCode == 200){
      return (jsonDecode(res.body) as List).map((j)=> ClassSessionModel.fromJson(j)).toList();
    }
    throw Exception("Failed to load weekly schedule");
  }

  static Future<List<ClassRequestHistory>> fetchRequestHistory(int coachId) async {
    final res = await http.get(Uri.parse('$baseUrl/$coachId/class-requests'));
    if(res.statusCode == 200){
      List<dynamic> data = jsonDecode(res.body);
      return data.map((json) => ClassRequestHistory.fromJson(json)).toList();    
    }
    throw Exception("Failed to load request history");
  }

  static Future<List<MyClassOffering>> fetchMyClasses(int coachId) async {
    final res = await http.get(Uri.parse('$baseUrl/$coachId/classes'));
    if(res.statusCode == 200){
      List<dynamic> data = jsonDecode(res.body);
      return data.map((json) => MyClassOffering.fromJson(json)).toList();
    }
    throw Exception("Failed to load my classes");
  }
}
