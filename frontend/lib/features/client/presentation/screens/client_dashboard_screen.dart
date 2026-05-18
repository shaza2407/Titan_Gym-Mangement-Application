// lib/features/client/presentation/screens/client_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'client_profile_screen.dart';
import 'client_scan_screen.dart';
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

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Logout',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out? You will need to sign in again to access your account.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
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
        _ctrl.loadStats(widget.token);
        return Consumer<ClientDashboardController>(
          builder: (context, ctrl, _) => _buildHomeTab(ctrl),
        );
      case 1:
        return _buildPlaceholderTab('Schedule');
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
      selectedItemColor: const Color(0xFF4F46E5),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Schedule',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Scan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  // ── Home Tab ──────────────────────────────────────────────────────────────
  Widget _buildHomeTab(ClientDashboardController ctrl) {
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Dashboard',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          stats?.name != null
                              ? 'Welcome back, ${stats!.name}!'
                              : 'Welcome back!',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
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
                              '3',
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
                      onPressed: () => _confirmLogout(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Subscription Card ─────────────────────────────────
            if (stats != null) _buildSubscriptionCard(stats),
            const SizedBox(height: 12),

            // ── Membership Status Card ────────────────────────────
            if (stats != null) _buildMembershipCard(stats),
            const SizedBox(height: 16),

            // ── Stats Row ─────────────────────────────────────────
            Row(
              children: [
                _buildStatCard(
                  Icons.trending_up,
                  stats != null ? '${stats.daysThisWeek}/7' : '-',
                  'Days This\nWeek',
                  const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  Icons.emoji_events_outlined,
                  stats != null ? '${stats.currentStreak} days' : '-',
                  'Current Streak',
                  const Color(0xFFFF9800),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  Icons.qr_code,
                  stats != null ? '${stats.totalVisits}' : '-',
                  'Total Visits',
                  const Color(0xFF4F46E5),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Actions ──────────────────────────────────────────
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
                    'Actions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Access your fitness features',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _buildActionItem(
                    Icons.notifications_outlined,
                    'My Gym${stats?.gymName != null ? ' - ${stats!.gymName}' : ''}',
                    'View announcements and enroll in classes',
                    () {},
                  ),
                  _buildActionItem(
                    Icons.track_changes_outlined,
                    'Training Plans',
                    'Generate personalized workout plans',
                    () {},
                  ),
                  _buildActionItem(
                    Icons.emoji_events_outlined,
                    'My Badges',
                    'View your achievements',
                    () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Achievements ──────────────────────────────────────
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
                    'My Achievements',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Unlock badges by reaching milestones',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _buildBadge('🎉', 'First Timer', true),
                      _buildBadge('💪', '3 Day Warrior', true),
                      _buildBadge('🔥', 'Weekly Streak', true),
                      _buildBadge('🏆', 'Monthly Champion', false),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Subscription Card ─────────────────────────────────────────────────────
  Widget _buildSubscriptionCard(DashboardStatsModel stats) {
    final isExpired = stats.isExpired;
    final isSuspended = stats.isSuspended;
    final isActive = stats.isActive;

    final bgColor = isActive ? const Color(0xFFE8F5E9) : Colors.red.shade50;
    final badgeColor = isActive ? const Color(0xFF4CAF50) : Colors.red;
    final badgeText = isActive
        ? 'Active'
        : isExpired
        ? 'Expired'
        : 'Suspended';
    final label = isExpired
        ? 'Subscription Expired'
        : isSuspended
        ? 'Subscription'
        : 'Active Subscription';
    final expiryText = isExpired
        ? 'Expired on ${stats.subscriptionEnd ?? ''} — Please renew'
        : 'Expires ${stats.subscriptionEnd ?? ''} (${stats.daysRemaining} days)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  stats.subscription ?? '-',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expiryText,
                  style: TextStyle(
                    color: isExpired ? Colors.red : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Membership Status Card ────────────────────────────────────────────────
  Widget _buildMembershipCard(DashboardStatsModel stats) {
    final isSuspended = stats.isSuspended;
    final bgColor = isSuspended ? Colors.red.shade50 : const Color(0xFFF0F0FF);
    final iconColor = isSuspended ? Colors.red : const Color(0xFF4F46E5);
    final badgeColor = isSuspended ? Colors.red : const Color(0xFF4F46E5);
    final statusText = isSuspended ? 'Suspended' : 'Active Member';
    final subText = isSuspended
        ? 'Your membership has been suspended — contact gym'
        : 'Member of ${stats.gymName ?? 'your gym'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isSuspended ? Icons.block : Icons.verified_user_outlined,
                color: iconColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subText,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isSuspended ? 'Suspended' : 'Active',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            Icon(icon, color: const Color(0xFF4CAF50), size: 22),
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

  Widget _buildBadge(String emoji, String label, bool earned) {
    return Container(
      decoration: BoxDecoration(
        color: earned ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: earned ? const Color(0xFF4CAF50) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            earned ? emoji : '🏆',
            style: TextStyle(
              fontSize: 32,
              color: earned ? null : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: earned ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String name) {
    return Center(
      child: Text(
        name,
        style: const TextStyle(fontSize: 24, color: Colors.grey),
      ),
    );
  }
}
