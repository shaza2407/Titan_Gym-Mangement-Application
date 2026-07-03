import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/announcement_controller.dart';
import '../../domain/announcement_model.dart';
import 'create_announcement_screen.dart';

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
  late final AnnouncementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnnouncementController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadAnnouncements(
        token: widget.token,
        gymId: widget.gymId,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<AnnouncementController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: _buildAppBar(),
            body: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.errorMessage != null
                    ? _buildError(controller)
                    : RefreshIndicator(
                        onRefresh: () => controller.loadAnnouncements(
                          token: widget.token,
                          gymId: widget.gymId,
                        ),
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildCreateButton(controller),
                            const SizedBox(height: 16),
                            if (controller.announcements.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: Center(
                                  child: Text(
                                    'No announcements yet',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            else
                              ...controller.announcements
                                  .map((a) => _buildCard(a)),
                          ],
                        ),
                      ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
    );
  }

  Widget _buildError(AnnouncementController controller) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            controller.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => controller.loadAnnouncements(
              token: widget.token,
              gymId: widget.gymId,
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(AnnouncementController controller) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: controller,
                child: CreateAnnouncementScreen(
                  token: widget.token,
                  gymId: widget.gymId,
                ),
              ),
            ),
          );
          if (created == true) {
            controller.loadAnnouncements(
              token: widget.token,
              gymId: widget.gymId,
            );
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Announcement',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Announcement a) {
    return Container(
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
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(a.body,
              style:
                  const TextStyle(color: Colors.black87, fontSize: 13)),
          const SizedBox(height: 10),
          Text(_formatDate(a.date),
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}