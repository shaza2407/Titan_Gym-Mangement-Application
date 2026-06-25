import 'package:flutter/material.dart';

const _cardColors = [
  Color(0xFFE9ECFF),
  Color(0xFFFFF3E0),
  Color(0xFFE6F7EF),
];

class Announcement {
  final String id;
  final String title;
  final String body;
  final DateTime date;
  final Color color;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.color,
  });

  factory Announcement.fromJson(Map<String, dynamic> json, int index) {
    return Announcement(
      id:    json['announce_id'].toString(),
      title: json['title']      as String,
      body:  json['content']    as String,
      date:  DateTime.parse(json['created_at'] as String),
      color: _cardColors[index % _cardColors.length],
    );
  }
}

class CreateAnnouncementRequest {
  final String title;
  final String content;
  final String receiver;

  const CreateAnnouncementRequest({
    required this.title,
    required this.content,
    required this.receiver,
  });

  Map<String, dynamic> toJson() => {
    'title':    title,
    'content':  content,
    'reciever': receiver,
  };
}