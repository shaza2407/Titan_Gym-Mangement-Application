import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/admin_gym_controller.dart';
import '../data/gym_repository.dart';
import '../../shared/logout_button.dart';


class GymDashboardScreen extends StatefulWidget {
  final GymModel gym;
  final String token;

  const GymDashboardScreen({
    super.key,
    required this.gym,
    required this.token,
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
          backgroundColor: const Color(0xFFEEF0F8),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildBody(controller)),
                _buildBottomNav(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF4F46E5),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admin Dashboard',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(color: Color(0xFF1D9E75), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(widget.gym.gymName,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white),onPressed: () => showLogoutDialog(context)),
        ],
      ),
    );
  }

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
              Text(controller.statsError!, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => controller.loadDashboardStats(
                    token: widget.token, gymId: widget.gym.gymID),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final stats = controller.dashboardStats!;
    return RefreshIndicator(
      onRefresh: () => controller.loadDashboardStats(token: widget.token, gymId: widget.gym.gymID),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatsGrid(stats),
          const SizedBox(height: 20),
          const Text('QUICK ACTIONS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: Colors.grey, letterSpacing: 0.6)),
          const SizedBox(height: 10),
          _buildQuickActions(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(GymDashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _statCard(Icons.people_outline,  const Color(0xFF4F46E5), 'Total Members',        stats.totalMembers.toString()),
        _statCard(Icons.attach_money,    const Color(0xFF1D9E75), 'Active Subscriptions', stats.activeSubscriptions.toString()),
        _statCard(Icons.qr_code_scanner, const Color(0xFFD85A30), "Today's Attendance",   stats.todayAttendance.toString()),
        _statCard(Icons.bar_chart,       const Color(0xFFBA7517), 'Monthly Revenue',      '\$${stats.monthlyRevenue.toStringAsFixed(0)}'),
      ],
    );
  }

  Widget _statCard(IconData icon, Color color, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 26),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      (Icons.campaign_outlined,   const Color(0xFF4F46E5), 'Announcements',       'Create and manage gym announcements'),
      (Icons.calendar_today,      const Color(0xFF185FA5), 'Schedule Management', 'Manage classes and timetables'),
      (Icons.people_outline,      const Color(0xFF0F6E56), 'Member Management',   'View and manage gym members'),
      (Icons.fitness_center,      const Color(0xFF7A3FA5), 'Coach Management',    'View and manage gym coaches'),
      (Icons.person_add_outlined, const Color(0xFF4F46E5), 'Add New Member',      'Enroll a new member to the gym'),
      (Icons.analytics_outlined,  const Color(0xFFBA7517), 'Analytics Dashboard', 'View revenue and performance metrics'),
      (Icons.tune,                const Color(0xFF185FA5), 'Gym Settings',        "Update this gym's information"),
      (Icons.qr_code_scanner,     const Color(0xFFD85A30), 'Attendance Tracking', 'View attendance records and QR codes'),
      (Icons.local_offer_outlined,const Color(0xFF1D9E75), 'Retention Offers',    'Create retention offers and predictions'),
    ];

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: actions.asMap().entries.map((entry) {
          final i      = entry.key;
          final action = entry.value;
          final isLast = i == actions.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: () {},
                borderRadius: i == 0
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : isLast
                        ? const BorderRadius.vertical(bottom: Radius.circular(16))
                        : BorderRadius.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: action.$2.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(action.$1, color: action.$2, size: 19),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(action.$3, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(action.$4, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                    ],
                  ),
                ),
              ),
              if (!isLast) const Divider(height: 0, thickness: 0.5, indent: 64),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      (Icons.dashboard,      'Dashboard'),
      (Icons.people_outline, 'Members'),
      (Icons.calendar_today, 'Schedule'),
      (Icons.person_outline, 'Profile'),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final active = entry.key == 0;
          final item   = entry.value;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.$1, color: active ? const Color(0xFF4F46E5) : Colors.grey, size: 24),
                const SizedBox(height: 3),
                Text(item.$2,
                    style: TextStyle(
                      fontSize: 10,
                      color: active ? const Color(0xFF4F46E5) : Colors.grey,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}