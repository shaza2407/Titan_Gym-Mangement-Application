import 'package:flutter/material.dart';

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
  // TODO: replace with real data fetched from backend
  final List<Announcement> _announcements = [
    Announcement(
      id: '1',
      title: 'New Yoga Classes Starting Next Week!',
      body:
          'Join our new morning yoga sessions every Monday and Wednesday at 7:00 AM.',
      date: DateTime(2026, 2, 5),
      color: const Color(0xFFE9ECFF),
    ),
    Announcement(
      id: '2',
      title: 'Gym Maintenance on Feb 15',
      body:
          'The gym will be closed for maintenance from 2:00 PM to 6:00 PM on February 15th.',
      date: DateTime(2026, 2, 3),
      color: const Color(0xFFFFF3E0),
    ),
    Announcement(
      id: '3',
      title: 'Monthly Fitness Challenge',
      body:
          'Participate in our February challenge! Attend 20 classes this month and win a free supplement package.',
      date: DateTime(2026, 2, 1),
      color: const Color(0xFFE6F7EF),
    ),
  ];

  bool _loading = false;

  Future<void> _deleteAnnouncement(String id) async {
    setState(() => _announcements.removeWhere((a) => a.id == id));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement deleted')),
      );
    }
    // TODO: call backend DELETE endpoint here
  }

  void _openCreateAnnouncementSheet() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Announcement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Title',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Message',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final title = titleController.text.trim();
                    final body = bodyController.text.trim();
                    if (title.isEmpty || body.isEmpty) return;

                    setState(() {
                      _announcements.insert(
                        0,
                        Announcement(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: title,
                          body: body,
                          date: DateTime.now(),
                          color: const Color(0xFFE9ECFF),
                        ),
                      );
                    });

                    Navigator.pop(sheetContext);
                    // TODO: call backend POST endpoint here
                  },
                  child: const Text('Publish',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _openCreateAnnouncementSheet,
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
                            Text(
                              a.body,
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 13),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _formatDate(a.date),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: () => _deleteAnnouncement(a.id),
                                icon: const Icon(Icons.delete_outline,
                                    size: 16, color: Colors.black),
                                label: const Text('Delete',
                                    style: TextStyle(color: Colors.black)),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
    );
  }
}