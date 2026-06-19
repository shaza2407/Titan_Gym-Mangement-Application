import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/features/shared/api_constants.dart';
import 'package:frontend/features/shared/invitation_accept_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final int userId;
  final String token;

  const NotificationsScreen({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  static const accentColor = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications/${widget.userId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _notifications = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(String id, int index) async {
    await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/notifications/$id/read'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    setState(() => _notifications[index]['is_read'] = true);
  }

  Future<void> _markAllAsRead() async {
    await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/notifications/${widget.userId}/read-all'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    setState(() {
      for (var n in _notifications) {
        n['is_read'] = true;
      }
    });
  }

  int get _unreadCount =>
      _notifications.where((n) => n['is_read'] == false).length;

  IconData _iconForType(String type) {
    switch (type) {
      case 'gym_invite_client':
        return Icons.fitness_center;
      case 'gym_invite_coach':
        return Icons.sports_gymnastics;
      case 'coach_class_request':    
        return Icons.calendar_today;  
      default:
        return Icons.notifications;
    }
  }

  String _timeAgo(String createdAt) {
    final date = DateTime.parse(createdAt).toLocal();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(
              _unreadCount > 0 ? '$_unreadCount unread' : 'All caught up',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read',
                  style: TextStyle(color: accentColor, fontSize: 12)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No notifications yet',
                          style: TextStyle(color: Colors.grey, fontSize: 15)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final isRead = n['is_read'] as bool;
                      final type = n['type'] as String? ?? '';

                      return GestureDetector(
                        onTap: () {
  if (!isRead) _markAsRead(n['id'], index);
    if (type == 'gym_invite_client' || type == 'gym_invite_coach') {
    final data = n['data'] as Map<String, dynamic>? ?? {};
    final gymId = int.tryParse(data['gym_id']?.toString() ?? '');
    final inviteToken = data['invite_token']?.toString() ?? '';
    final gymName = data['gym_name']?.toString() ?? 'Gym';

    if (gymId != null && inviteToken.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvitationScreen(
            gymId: gymId,
            inviteToken: inviteToken,
            gymName: gymName,
            authToken: widget.token,
            role: type == 'gym_invite_coach' ? 'coach' : 'client'
          ),
        ),
      );
    }
  }
},
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRead
                                ? Colors.white
                                : accentColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isRead
                                  ? Colors.transparent
                                  : accentColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_iconForType(type),
                                    color: accentColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n['title'] ?? '',
                                        style: TextStyle(
                                            fontWeight: isRead
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                            fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(n['body'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12)),
                                    const SizedBox(height: 6),
                                    Text(
                                      _timeAgo(n['created_at']),
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}