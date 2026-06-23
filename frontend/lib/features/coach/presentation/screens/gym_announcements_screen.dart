import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/coach_gyms_controller.dart';
import 'coach_ui_utils.dart';
import '../widgets/custom_bottom_nav.dart';
import 'coach_dashboard_screen.dart';
import 'coach_gyms_screen.dart';

class GymAnnouncementsScreen extends StatefulWidget {
  final String token;
  final int gymId;
  final String gymName;

  const GymAnnouncementsScreen({
    super.key,
    required this.token,
    required this.gymId,
    required this.gymName,
  });

  @override
  State<GymAnnouncementsScreen> createState() => _GymAnnouncementsScreenState();
}

class _GymAnnouncementsScreenState extends State<GymAnnouncementsScreen> {
  late final GymAnnouncementsController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = GymAnnouncementsController();
    _ctrl.loadGymAnnouncements(widget.token, widget.gymId);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<GymAnnouncementsController>(
        builder: (context, ctrl, _) {
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
                  Text(
                    '${widget.gymName} — Announcements',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Gym notices and updates',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            body: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () =>
                        ctrl.loadGymAnnouncements(widget.token, widget.gymId),
                    child: ctrl.announcements.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              EmptyState(
                                title: 'No announcements yet',
                                subtitle:
                                    'This gym has no announcements right now.',
                                icon: Icons.notifications_none,
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: ctrl.announcements.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) => AnnouncementCard(
                              announcement: ctrl.announcements[index],
                              showGymName: false,
                            ),
                          ),
                  ),
            bottomNavigationBar: CustomBottomNav(
              currentIndex: 2, // 2 = Gyms Tab
              onTap: (i) {
                if (i == 2) {
                  Navigator.pop(
                    context,
                  ); // Already on Gyms tab, just go back to the list
                } else {
                  // Jump to Dashboard and switch to the selected tab
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CoachDashboardScreen(
                        token: widget.token,
                        initialIndex: i,
                      ),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
