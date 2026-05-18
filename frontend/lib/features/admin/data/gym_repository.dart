import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class GymModel {
  final int gymID;
  final int adminID;
  final String gymName;
  final double subscriptionPrice;
  final String location;
  final String status;
  final String qrCode;
  final String gymType;
  final String openingHours;
  final String closingHours;

  GymModel({
    required this.gymID,
    required this.adminID,
    required this.gymName,
    required this.subscriptionPrice,
    required this.location,
    required this.status,
    required this.qrCode,
    required this.gymType,
    required this.openingHours,
    required this.closingHours,
  });

  factory GymModel.fromJson(Map<String, dynamic> json) {
    return GymModel(
      gymID:             json['gymID'],
      adminID:           json['adminID'],
      gymName:           json['gymName'],
      subscriptionPrice: (json['subscriptionPrice'] as num).toDouble(),
      location:          json['location'],
      status:            json['status'],
      qrCode:            json['QRCode'],
      gymType:           json['gymType'],
      openingHours:      json['openingHours'],
      closingHours:      json['closingHours'],
    );
  }
}

class GymRepository {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  // GET /gyms/
  Future<List<GymModel>> getGyms({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/gyms/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => GymModel.fromJson(e)).toList();
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  // POST /gyms/
  Future<GymModel> createGym({
    required String token,
    required String gymName,
    required double subscriptionPrice,
    required String location,
    required String status,
    required String gymType,
    required String openingHours,
    required String closingHours,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gyms/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'gymName':           gymName,
        'subscriptionPrice': subscriptionPrice,
        'location':          location,
        'status':            status,
        'gymType':           gymType,
        'openingHours':      openingHours,
        'closingHours':      closingHours,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return GymModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }
}