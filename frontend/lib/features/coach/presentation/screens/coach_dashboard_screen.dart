import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/logout_button.dart';
import '../controllers/coach_dashboard_controller.dart';
import '../../domain/coach_dashboard_model.dart';
import 'coach_schedule_screen.dart';
import 'coach_profile_screen.dart';

class CoachDashboardScreen extends StatefulWidget {
  final String token;
  const CoachDashboardScreen({super.key, required this.token});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  int _currentIndex = 0;
  late CoachDashboardController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = CoachDashboardController();
    _ctrl.loadAll(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        _ctrl.loadAll(widget.token);
        return Consumer<CoachDashboardController>(
          builder: (context, ctrl, _) => _buildHomeTab(ctrl),
        );
      case 1:
        return CoachScheduleScreen(
          token: widget.token,
          onBack: () => setState(() => _currentIndex = 0),
        );
      case 2:
        return CoachProfileScreen(
          token: widget.token,
          onBack: () => setState(() => _currentIndex = 0),
        );
      default:
        return Consumer<CoachDashboardController>(
          builder: (context, ctrl, _) => _buildHomeTab(ctrl),
        );
    }
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF4F46E5),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Schedule',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildHomeTab(CoachDashboardController ctrl) {
    if (ctrl.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = ctrl.stats;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App Bar ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF4F46E5),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coach Dashboard',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Welcome back, Coach!',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {},
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '2',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_outlined),
                      onPressed: () => showLogoutDialog(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Stats Row ─────────────────────────────────────────
            Row(
              children: [
                _buildStatCard(
                  Icons.calendar_today_outlined,
                  '${stats?.weeklyClasses ?? 0}',
                  'Weekly\nClasses',
                  const Color(0xFF4F46E5),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  Icons.people_outline,
                  '${stats?.totalStudents ?? 0}',
                  'Total\nStudents',
                  const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  Icons.fitness_center_outlined,
                  '${stats?.activeGyms ?? 0}',
                  'Active\nGyms',
                  const Color(0xFFFF9800),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Upcoming Classes ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Change the section title from "Upcoming Classes" to "Today's Classes"
                  const Text(
                    "Today's Classes", // ← changed
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _todayLabel(),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (ctrl.upcoming.isEmpty)
                    const Center(
                      child: Text(
                        'No classes for today', // ← changed message
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...ctrl.upcoming.map((c) => _buildUpcomingCard(c)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Quick Actions ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Manage your coaching activities',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _buildActionItem(
                    Icons.calendar_month_outlined,
                    'My Schedule & Classes',
                    'View schedule and manage class requests',
                    () => setState(() => _currentIndex = 1),
                  ),
                  _buildActionItem(
                    Icons.person_outline,
                    'My Profile',
                    'Update your coach information',
                    () => setState(() => _currentIndex = 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
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
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingCard(CoachUpcomingClassModel c) {
    final isFull = c.currentClients >= c.maxClients;
    final capacityColor = isFull
        ? Colors.red
        : c.currentClients / c.maxClients > 0.8
        ? Colors.orange
        : const Color(0xFF4CAF50);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_month, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  c.gymName ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(c.startTime),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: capacityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${c.currentClients}/${c.maxClients}',
                  style: TextStyle(
                    color: capacityColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
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
            Icon(icon, color: const Color(0xFF4F46E5), size: 22),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month]} ${now.day}, ${now.year}';
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final min = parts[1];
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour > 12
        ? hour - 12
        : hour == 0
        ? 12
        : hour;
    return '${h.toString().padLeft(2, '0')}:$min $period';
  }
}
