class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String createdAt;
  final bool isRead;
  final Map<String, dynamic> data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
    required this.data,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id:        map['id']?.toString()         ?? '',
      title:     map['title']     as String?   ?? '',
      body:      map['body']      as String?   ?? '',
      type:      map['type']      as String?   ?? '',
      createdAt: map['created_at'] as String?  ?? '',
      isRead:    map['is_read']   as bool?     ?? false,
      data:      map['data'] as Map<String, dynamic>? ?? {},
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id:        id,
      title:     title,
      body:      body,
      type:      type,
      createdAt: createdAt,
      isRead:    isRead ?? this.isRead,
      data:      data,
    );
  }
}