import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/admin_gym_controller.dart';
import '../data/gym_repository.dart';
import '../../shared/logout_button.dart';
import 'client_management_screen.dart';
import 'coach_management_screen.dart';
import 'invite_member_screen.dart';
import 'attendance_tracking_screen.dart';
import 'analytics_screen.dart';

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
      context.read<AdminGymController>().loadDashboardStats(
            token: widget.token,
            gymId: widget.gym.gymID,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminGymController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: _buildAppBar(),
          body: _buildBody(controller),
        );
      },
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Admin Dashboard',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            Positioned(
              right: 8, top: 8,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 9)),
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout_outlined, color: Colors.black),
          onPressed: () => showLogoutDialog(context),
        ),
      ],
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody(AdminGymController controller) {
    if (controller.isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.statsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(controller.statsError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => controller.loadDashboardStats(
                    token: widget.token, gymId: widget.gym.gymID),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.dashboardStats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = controller.dashboardStats!; // now safe

    return RefreshIndicator(
      onRefresh: () => controller.loadDashboardStats(
          token: widget.token, gymId: widget.gym.gymID),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Gym selector
              _buildGymSelector(),
              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _buildStatCard(Icons.people_alt_outlined,
                      '${stats.totalMembers}', 'Total\nMembers', const Color(0xFF4F46E5)),
                  const SizedBox(width: 12),
                  _buildStatCard(Icons.attach_money,
                      '${stats.activeSubscriptions}', 'Active\nSubs', const Color(0xFF1D9E75)),
                  const SizedBox(width: 12),
                  _buildStatCard(Icons.qr_code_2_outlined,
                      '${stats.todayAttendance}', "Today's\nAttendance", const Color(0xFFD85A30)),
                ],
              ),

              // Revenue card
              const SizedBox(height: 16),

              // Quick actions
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Text('Access key management features',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 16),
                    _buildActionItem(
                      Icons.people_outline,
                      const Color.fromARGB(255, 66, 0, 173),
                      'Client Management',
                      'View and manage gym clients',
                      () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ClientManagementScreen(
                            token: widget.token, gym: widget.gym),
                      )),
                    ),
                    _buildActionItem(
                      Icons.fitness_center,
                      const Color.fromARGB(255, 66, 0, 173),
                      'Coach Management',
                      'View and manage gym coaches',
                      () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CoachManagementScreen(
                            token: widget.token, gym: widget.gym),
                      )),
                    ),
                    _buildActionItem(
                      Icons.person_add_outlined,
                      const Color.fromARGB(255, 66, 0, 173),
                      'Add New Member',
                      'Enroll a new member to the gym',
                      () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => InviteMemberScreen(
                            gym: widget.gym, token: widget.token),
                      )),
                    ),
                    _buildActionItem(
                      Icons.campaign_outlined,
                      const Color.fromARGB(255, 66, 0, 173),
                      'Announcements',
                      'Create and manage gym announcements',
                      () {},
                    ),
                    _buildActionItem(
                      Icons.analytics_outlined,
                      const Color.fromARGB(255, 66, 0, 173),
                      'Analytics Dashboard',
                      'View revenue and performance metrics',
                      () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AnalyticsScreen(
                            token: widget.token, gymId: widget.gym.gymID),
                      )),
                    ),
                    _buildActionItem(
                      Icons.qr_code_scanner,
                      const Color.fromARGB(255, 66, 0, 173),
                      'Attendance Tracking',
                      'View attendance records and QR codes',
                      () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AttendanceTrackingScreen(
                            token: widget.token, gym: widget.gym),
                      )),
                    ),
                    _buildActionItem(
                      Icons.tune,
                      const Color.fromARGB(255, 66, 0, 173),
                      'Gym Settings',
                      "Update this gym's information",
                      () {},
                    ),
                    _buildActionItem(
                      Icons.local_offer_outlined,
                      const Color.fromARGB(255, 66, 0, 173),
                      'Retention Offers',
                      'Create retention offers and predictions',
                      () {},
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

  // ── Gym selector ──────────────────────────────────────────────────────────
  Widget _buildGymSelector() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
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
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.business_outlined,
                  color: Color(0xFF4F46E5), size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Currently Managing',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(widget.gym.gymName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4F46E5)),
          ],
        ),
      ),
    );
  }

  // ── Stat card ─────────────────────────────────────────────────────────────
  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ── Action item ───────────────────────────────────────────────────────────
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
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
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
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}