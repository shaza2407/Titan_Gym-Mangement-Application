// lib/features/client/presentation/screens/client_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/logout_button.dart';
import 'client_profile_screen.dart';
import 'client_scan_screen.dart';
import 'client_schedule_screen.dart';
import 'training_plan_screen.dart';
import 'client_achievement_screen.dart';
import '../controllers/client_dashboard_controller.dart';
import '../../domain/dashboard_model.dart';

class ClientDashboardScreen extends StatefulWidget {
  final String token;
  const ClientDashboardScreen({super.key, required this.token});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  int _currentIndex = 0;
  late ClientDashboardController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ClientDashboardController();
    _ctrl.loadStats(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6), // Light grey background
        appBar: _currentIndex == 0 ? _buildAppBar() : null,
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5), // Indigo Accent
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'My Dashboard',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Text(
                'Welcome back!',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {},
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '4',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(right: 16, left: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.logout_outlined,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => showLogoutDialog(context),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        _ctrl.loadStats(widget.token);
        return Consumer<ClientDashboardController>(
          builder: (context, ctrl, _) => _buildHomeTab(ctrl),
        );
      case 1:
        return ClientScheduleScreen(
          token: widget.token,
          onBack: () => setState(() => _currentIndex = 0),
        );
      case 2:
        return ClientScanScreen(
          token: widget.token,
          onBack: () => setState(() => _currentIndex = 0),
        );
      case 3:
        return ClientProfileScreen(
          token: widget.token,
          onBack: () => setState(() => _currentIndex = 0),
        );
      default:
        return Consumer<ClientDashboardController>(
          builder: (context, ctrl, _) => _buildHomeTab(ctrl),
        );
    }
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      selectedItemColor: const Color(0xFF4F46E5), // Indigo selected tab
      unselectedItemColor: const Color(0xFF9CA3AF),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
      ],
    );
  }

  Widget _buildHomeTab(ClientDashboardController ctrl) {
    if (ctrl.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
    }

    final stats = ctrl.stats;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeeklyGoalCard(stats),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Access your fitness features',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _buildActionCard(
                    icon: Icons.qr_code,
                    title: 'Scan QR Code',
                    subtitle: 'Check in to the gym',
                    isHighlighted: true,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                  _buildActionCard(
                    icon: Icons.notifications_none,
                    title: 'My Gym - Titan Fitness',
                    subtitle: 'View announcements and enroll in classes',
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  _buildActionCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'My Schedule',
                    subtitle: 'View and manage your classes',
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  _buildActionCard(
                    icon: Icons.track_changes_outlined,
                    title: 'Training Plans',
                    subtitle: 'Generate personalized workout plans',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrainingPlanScreen(
                            token: widget.token,
                            onBack: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    subtitle: 'Update personal information',
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                  _buildActionCard(
                    icon: Icons.military_tech_outlined,
                    title: 'My Badges',
                    subtitle: 'View your achievements',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientAchievementScreen(
                            token: widget.token,
                            onBack: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyGoalCard(DashboardStatsModel? stats) {
    // Fallback static data to match the UI if not available
    final int days = stats?.daysThisWeek ?? 4;
    final int target = 5;
    final double percent = (days / target) * 100;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Attendance Goal',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
          ),
          const SizedBox(height: 4),
          const Text(
            'Keep up the great work!',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$days out of $target days',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
              ),
              Text(
                '${percent.toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: const Color(0xFFE5E7EB),
              color: const Color(0xFF111827), // Dark navy / almost black
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isHighlighted = false,
    required VoidCallback onTap,
  }) {
    final borderColor = isHighlighted ? const Color(0x8010B981) : const Color(0xFFE5E7EB);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF10B981), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
