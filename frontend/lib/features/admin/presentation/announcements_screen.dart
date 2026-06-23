import 'package:flutter/material.dart';
import 'dart:convert';
import '../../shared/api_constants.dart';
import 'package:http/http.dart' as http;
import 'create_announcement_screen.dart';

// Color cycle for cards coming from backend
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
      id: json['announce_id'].toString(),
      title: json['title'],
      body: json['content'],
      date: DateTime.parse(json['created_at']),
      color: _cardColors[index % _cardColors.length],
    );
  }
}

class AnnouncementsScreen extends StatefulWidget {
  final String token;
  final int gymId;

  const AnnouncementsScreen({
    super.key,
    required this.token,
    required this.gymId,
  });

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Announcement> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  // ── GET ──────────────────────────────────────────────────────────────────
  Future<void> _fetchAnnouncements() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/admin/gyms/${widget.gymId}/announcements'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _announcements = data
              .asMap()
              .entries
              .map((e) => Announcement.fromJson(e.value, e.key))
              .toList();
        });
      } else {
        _showError('Failed to load announcements');
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Announcements',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text('Create and manage gym announcements',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(                          // pull-to-refresh bonus
              onRefresh: _fetchAnnouncements,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                    onPressed: () async {
                      final created = await Navigator.push<bool>(context,
                      MaterialPageRoute(           
                        builder: (_) => CreateAnnouncementScreen(token: widget.token,gymId: widget.gymId,
                        ),
                       ),
                      );
                      if (created == true) {
                         _fetchAnnouncements();
                         }
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Create Announcement',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_announcements.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text('No announcements yet',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._announcements.map((a) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: a.color,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.notifications_outlined,
                                      size: 18, color: Colors.black87),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      a.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(a.body,
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 13)),
                              const SizedBox(height: 10),
                              Text(_formatDate(a.date),
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 10),
                            ],
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}