//done
import 'package:flutter/material.dart';
import 'package:frontend/features/admin/presentation/screens/retention_offer_screen.dart';
import 'package:provider/provider.dart';
import '../controller/gym_dashboard_controller.dart';
import '../../../shared/logout_button.dart';
import 'client_management_screen.dart';
import 'coach_management_screen.dart';
import 'invite_member_screen.dart';
import 'attendance_tracking_screen.dart';
import 'gym_settings_screen.dart';
import 'package:frontend/features/Services/notifications_screen.dart';
import 'package:frontend/features/Services/token_helper.dart';
import 'announcements_screen.dart';
import '../../domain/gym_model.dart';

class GymDashboardScreen extends StatefulWidget {
  final GymModel gym;
  final String token;
  final void Function(int)? onTabChange;

  const GymDashboardScreen({
    super.key,
    required this.gym,
    required this.token,
    this.onTabChange,
  });

  @override
  State<GymDashboardScreen> createState() => _GymDashboardScreenState();
}

class _GymDashboardScreenState extends State<GymDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GymDashboardController>().loadDashboardStats(
            token: widget.token,
            gymId: widget.gym.gymID,
          );
    });
  }

  Future<void> _openGymSettings() async {
    final controller = context.read<GymDashboardController>();
    final freshGym = await controller.fetchFreshGym(
          token: widget.token,
          gymId: widget.gym.gymID,
        ) ??
        widget.gym;

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GymSettingsScreen(gym: freshGym, token: widget.token),
      ),
    );

    if (mounted) {
      controller.loadDashboardStats(
        token: widget.token,
        gymId: widget.gym.gymID,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GymDashboardController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: _buildAppBar(controller),
          body: _buildHomeTab(controller),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(GymDashboardController controller) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.grid_view_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.gym.gymName,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.black),
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NotificationsScreen(
                  userId: getUserIdFromToken(widget.token),
                  token: widget.token,
                  onDataChanged: () {
                    context.read<GymDashboardController>().loadDashboardStats(
                          token: widget.token,
                          gymId: widget.gym.gymID,
                        );
                  },
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.black),
          onPressed: _openGymSettings,
        ),
        IconButton(
          icon: const Icon(Icons.logout_outlined, color: Colors.black),
          onPressed: () => showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildHomeTab(GymDashboardController controller) {
    if (controller.isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.statsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              controller.statsError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => controller.loadDashboardStats(
                  token: widget.token, gymId: widget.gym.gymID),
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

    final stats = controller.dashboardStats;

    return RefreshIndicator(
      onRefresh: () => controller.loadDashboardStats(
          token: widget.token, gymId: widget.gym.gymID),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGymSelector(),
              const SizedBox(height: 16),

              // Stats Row
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatCard(
                      Icons.attach_money,
                      '${stats?.activeSubscriptions ?? 0}',
                      'Active \nMembers',
                      const Color(0xFF1D9E75),
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      Icons.qr_code_2_outlined,
                      '${stats?.todayAttendance ?? 0}',
                      "Today's\nAttendance",
                      const Color(0xFFD85A30),
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      Icons.sports_gymnastics_sharp,
                      '${stats?.totalClasses ?? 0}',
                      "Today's\nClasses",
                      const Color(0xFFFF9800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick Actions',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Text('Access key management features',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 16),
                    _buildActionItem(
                      Icons.campaign_outlined,
                      const Color(0xFF4F46E5),
                      'Announcements',
                      'Create and manage gym announcements',
                      () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AnnouncementsScreen(
                            token: widget.token, gymId: widget.gym.gymID),
                      )),
                    ),
                    _buildActionItem(
                      Icons.people_outline,
                      const Color(0xFF4F46E5),
                      'Client Management',
                      'View and manage gym members',
                      () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ClientManagementScreen(
                            token: widget.token, gym: widget.gym),
                      )),
                    ),
                    _buildActionItem(
                      Icons.fitness_center,
                      const Color(0xFF4F46E5),
                      'Coach Management',
                      'View and manage gym coaches',
                      () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CoachManagementScreen(
                            token: widget.token, gym: widget.gym),
                      )),
                    ),
                    _buildActionItem(
                      Icons.person_add_outlined,
                      const Color(0xFF4F46E5),
                      'Add New Member',
                      'Enroll a new member to the gym',
                      () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => InviteMemberScreen(
                            gym: widget.gym, token: widget.token),
                      )),
                    ),
                    _buildActionItem(
                      Icons.qr_code_scanner,
                      const Color(0xFF4F46E5),
                      'Attendance Tracking',
                      'View attendance records and QR codes',
                      () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AttendanceTrackingScreen(
                            token: widget.token, gym: widget.gym),
                      )),
                    ),
                    _buildActionItem(
                      Icons.tune,
                      const Color(0xFF4F46E5),
                      'Gym Settings',
                      "Update this gym's information",
                      _openGymSettings,
                    ),
                    _buildActionItem(
                      Icons.local_offer_outlined,
                      const Color(0xFF4F46E5),
                      'Retention Offers',
                      'Create retention offers and predictions',
                      () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => RetentionOfferScreen(
                            gymId: widget.gym.gymID, token: widget.token),
                      )),
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGymSelector() {
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).pop(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.business_outlined,
                  color: Color(0xFF4F46E5), size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Switch Gym',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_right, color: Color(0xFF4F46E5)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: Colors.grey.shade400, size: 24),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}