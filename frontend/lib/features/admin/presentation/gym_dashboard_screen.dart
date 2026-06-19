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
import 'gym_settings_screen.dart';
import 'package:frontend/features/Services/notifications_screen.dart';
import 'package:frontend/features/Services/token_helper.dart';

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
  int _currentIndex = 0;

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
          body: _buildCurrentTab(controller),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.grid_view_rounded,
                color: Colors.white, size: 20),
          ),
          // const SizedBox(width: 10),
          
          const Text(
            ' ',
            style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          Text(widget.gym.gymName,
                    style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold),
                ),
          const Text(
            ' Dashboard',
            style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(
                  userId: getUserIdFromToken(widget.token),
                  token: widget.token,
                ),
              ),
            ),
          ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.black),
          onPressed: () => Navigator.push(context,
            MaterialPageRoute(
              builder: (_) => GymSettingsScreen(gym: widget.gym,token: widget.token,),
            ),
          ),
      ),
        IconButton(
          icon: const Icon(Icons.logout_outlined, color: Colors.black),
          onPressed: () => showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildCurrentTab(AdminGymController controller) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab(controller);
      case 1:
        return AnalyticsScreen(
            token: widget.token, gymId: widget.gym.gymID);
      default:
        return _buildHomeTab(controller);
    }
  }

  Widget _buildHomeTab(AdminGymController controller) {
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
              // Gym selector
              _buildGymSelector(),
              const SizedBox(height: 16),

              // 2x2 Stats Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    Icons.people_alt_outlined,
                    '${stats?.totalMembers ?? 0}',
                    'Total Members',
                    const Color(0xFF4F46E5),
                  ),
                  _buildStatCard(
                    Icons.attach_money,
                    '${stats?.activeSubscriptions ?? 0}',
                    'Active Subscriptions',
                    const Color(0xFF1D9E75),
                  ),
                  _buildStatCard(
                    Icons.qr_code_2_outlined,
                    '${stats?.todayAttendance ?? 0}',
                    "Today's Attendance",
                    const Color(0xFFD85A30),
                  ),
                  _buildStatCard(
                    Icons.sports_gymnastics_sharp,
                    '\$${stats != null ? 'place holder' : '0'}',
                    'Todays Classes',
                    const Color(0xFFD85A30),
                  ),
                ],
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
                        style:
                            TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 16),
                    _buildActionItem(
                      Icons.campaign_outlined,
                      const Color(0xFF4F46E5),
                      'Announcements',
                      'Create and manage gym announcements',
                      () {},
                    ),
                    _buildActionItem(
                      Icons.people_outline,
                      const Color(0xFF4F46E5),
                      'Member Management',
                      'View and manage gym members',
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientManagementScreen(
                                token: widget.token, gym: widget.gym),
                          )),
                    ),
                    _buildActionItem(
                      Icons.fitness_center,
                      const Color(0xFF4F46E5),
                      'Coach Management',
                      'View and manage gym coaches',
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CoachManagementScreen(
                                token: widget.token, gym: widget.gym),
                          )),
                    ),
                    _buildActionItem(
                      Icons.person_add_outlined,
                      const Color(0xFF4F46E5),
                      'Add New Member',
                      'Enroll a new member to the gym',
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InviteMemberScreen(
                                gym: widget.gym, token: widget.token),
                          )),
                    ),
                    _buildActionItem(
                      Icons.qr_code_scanner,
                      const Color(0xFF4F46E5),
                      'Attendance Tracking',
                      'View attendance records and QR codes',
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttendanceTrackingScreen(
                                token: widget.token, gym: widget.gym),
                          )),
                    ),
                    _buildActionItem(
                      Icons.tune,
                      const Color(0xFF4F46E5),
                      'Gym Settings',
                      "Update this gym's information",
                      () => Navigator.push(context,
                          MaterialPageRoute(
                          builder: (_) => GymSettingsScreen(gym: widget.gym,token: widget.token,),
                         ),
                      ),
                    ),
                    _buildActionItem(
                      Icons.local_offer_outlined,
                      const Color(0xFF4F46E5),
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

  Widget _buildGymSelector() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Switch Gym',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_right,
                color: Color(0xFF4F46E5)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 35),
          const Spacer(),
          Text(label,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
        ],
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
    return InkWell(
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
                          fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}