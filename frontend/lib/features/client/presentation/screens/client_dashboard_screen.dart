// lib/features/client/presentation/screens/client_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/logout_button.dart';
import '../widgets/client_bottom_nav.dart';
import 'client_gym_screen.dart';
import 'client_profile_screen.dart';
import 'client_scan_screen.dart';
import '../controllers/client_dashboard_controller.dart';
import '../../domain/dashboard_model.dart';
import 'client_schedule_screen.dart';
import '../../../notification/token_helper.dart';
import '../../../notification/presentation/notifications_screen.dart';
import 'training_plan_screen.dart';
import 'client_achievement_screen.dart';
import '../controllers/client_achievement_controller.dart';
import 'subscription_blocked_screen.dart';
import '../../../shared/notifications/notification_badge_controller.dart';

class ClientDashboardScreen extends StatefulWidget {
  final String token;
  final ClientDashboardController? testDashCtrl;
  final ClientAchievementController? testAchCtrl;
  final NotificationBadgeController? testBadgeCtrl;

  const ClientDashboardScreen({
    super.key,
    required this.token,
    this.testDashCtrl,
    this.testAchCtrl,
    this.testBadgeCtrl,
  });

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  int _currentIndex = 0;
  late ClientDashboardController _ctrl;
  late ClientAchievementController _achievementCtrl;
  late NotificationBadgeController _badgeCtrl;

  static const int _kGym = 4;
  static const int _kTraining = 5;
  static const int _kAchievements = 6;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.testDashCtrl ?? ClientDashboardController();
    if (widget.testDashCtrl == null) _ctrl.loadStats(widget.token);

    _achievementCtrl = widget.testAchCtrl ?? ClientAchievementController();
    if (widget.testAchCtrl == null) {
      _achievementCtrl.loadAchievements(widget.token);
    }

    _badgeCtrl = widget.testBadgeCtrl ?? NotificationBadgeController();
    if (widget.testBadgeCtrl == null) {
      _badgeCtrl.load(widget.token, getUserIdFromToken(widget.token));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _achievementCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _ctrl),
        ChangeNotifierProvider.value(value: _achievementCtrl),
        ChangeNotifierProvider.value(value: _badgeCtrl),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: _currentIndex == 0 ? _buildAppBar() : null,
        body: Consumer<ClientDashboardController>(
          builder: (context, ctrl, _) => _buildBody(ctrl),
        ),
        bottomNavigationBar: ClientBottomNav(
          currentIndex: _currentIndex > 3 ? -1 : _currentIndex,
          onTap: (i) {
            if (i == 0) {
              _goHome();
            } else {
              setState(() => _currentIndex = i);
            }
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Consumer<ClientDashboardController>(
        builder: (context, ctrl, _) {
          final stats = ctrl.stats;
          return Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color.fromARGB(255, 63, 163, 77),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'My Dashboard',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    stats?.gymName ?? 'Welcome back!',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        _buildNotificationButton(),
        IconButton(
          icon: const Icon(Icons.logout_outlined, color: Colors.black),
          onPressed: () => showLogoutDialog(context),
        ),
      ],
    );
  }

  // ── Notification button with red dot ─────────────────────────────────────
  Widget _buildNotificationButton() {
    return AnimatedBuilder(
      animation: _badgeCtrl,
      builder: (context, _) {
        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.black),
              if (_badgeCtrl.hasUnread)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () async {
            bool dataChanged = false;

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationsScreen(
                  userId: getUserIdFromToken(widget.token),
                  token: widget.token,
                  onDataChanged: () => dataChanged = true,
                ),
              ),
            );

            if (!mounted) return;

            _badgeCtrl.load(widget.token, getUserIdFromToken(widget.token));

            if (dataChanged) {
              _ctrl.loadStats(widget.token);
            }
          },
        );
      },
    );
  }

  Widget _buildBody(ClientDashboardController ctrl) {
    final stats = ctrl.stats;

    switch (_currentIndex) {
      case 0:
        return _buildHomeTab(ctrl);

      case 1:
        if (_isAccessBlocked(stats)) {
          return SubscriptionBlockedScreen(
            reason: _blockReason(stats!),
            gymName: stats.gymName,
            onBack: _goHome,
          );
        }
        return ClientScheduleScreen(token: widget.token, onBack: _goHome);

      case 2:
        return ClientScanScreen(token: widget.token, onBack: _goHome);

      case 3:
        return ClientProfileScreen(token: widget.token, onBack: _goHome);

      case _kGym:
        if (_isAccessBlocked(stats)) {
          return SubscriptionBlockedScreen(
            reason: _blockReason(stats!),
            gymName: stats.gymName,
            onBack: _goHome,
          );
        }
        return ClientGymScreen(token: widget.token, onBack: _goHome);

      case _kTraining:
        if (_isAccessBlocked(stats)) {
          return SubscriptionBlockedScreen(
            reason: _blockReason(stats!),
            gymName: stats.gymName,
            onBack: _goHome,
          );
        }
        return TrainingPlanScreen(token: widget.token, onBack: _goHome);

      case _kAchievements:
        return ClientAchievementScreen(token: widget.token, onBack: _goHome);

      default:
        return _buildHomeTab(ctrl);
    }
  }

  bool _isAccessBlocked(DashboardStatsModel? stats) =>
      stats != null && (stats.isSuspended || stats.isExpired);

  SubscriptionBlockReason _blockReason(DashboardStatsModel stats) =>
      stats.isSuspended
      ? SubscriptionBlockReason.suspended
      : SubscriptionBlockReason.expired;

  void _navigateTo(int index) => setState(() => _currentIndex = index);

  void _goHome() {
    setState(() => _currentIndex = 0);
    _ctrl.loadStats(widget.token);
  }

  // ── Home Tab ──────────────────────────────────────────────────────────────
  Widget _buildHomeTab(ClientDashboardController ctrl) {
    if (ctrl.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ctrl.stats == null && ctrl.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                ctrl.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ctrl.loadStats(widget.token),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final stats = ctrl.stats;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stats != null) _buildSubscriptionCard(stats),
            const SizedBox(height: 12),

            // ── rest of the home tab exactly as before ──────────
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
                    'View Gym info and announcements',
                    () => _navigateTo(_kGym),
                  ),
                  _buildActionItem(
                    Icons.track_changes_outlined,
                    'Training Plans',
                    'Generate personalized workout plans',
                    () => _navigateTo(_kTraining),
                  ),
                  _buildActionItem(
                    Icons.emoji_events_outlined,
                    'My Badges',
                    'View your achievements',
                    () => _navigateTo(_kAchievements),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                  Consumer<ClientAchievementController>(
                    builder: (context, achCtrl, _) {
                      if (achCtrl.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (achCtrl.achievements.isEmpty) {
                        return const Text(
                          'No badges available.',
                          style: TextStyle(color: Colors.grey),
                        );
                      }
                      final unlocked = achCtrl.achievements
                          .where((a) => a.isUnlocked)
                          .toList();
                      final locked = achCtrl.achievements
                          .where((a) => !a.isUnlocked)
                          .toList();
                      final displayAch = [
                        ...unlocked,
                        ...locked,
                      ].take(4).toList();

                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                        children: displayAch.map((a) {
                          String shortName = a.name;
                          if (shortName.contains('—')) {
                            shortName = shortName.split('—').first.trim();
                          }
                          return _buildBadge(a.icon, shortName, a.isUnlocked);
                        }).toList(),
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

  // ── Subscription Card ─────────────────────────────────────────────────────
  Widget _buildSubscriptionCard(DashboardStatsModel stats) {
    final isExpired = stats.isExpired;
    final isSuspended = stats.isSuspended;

    final Color bgColor = isSuspended
        ? Colors.red.shade50
        : isExpired
        ? Colors.amber.shade50
        : const Color(0xFFE8F5E9);

    final Color badgeColor = isSuspended
        ? Colors.red
        : isExpired
        ? Colors.amber.shade700
        : const Color(0xFF4CAF50);

    final Color subTextColor = isSuspended
        ? Colors.red.shade700
        : isExpired
        ? Colors.amber.shade800
        : Colors.grey;

    final String badgeText = isSuspended
        ? 'Suspended'
        : isExpired
        ? 'Expired'
        : 'Active';

    final String label = isSuspended
        ? 'Subscription Suspended'
        : isExpired
        ? 'Subscription Expired'
        : 'Active Subscription';

    final String expiryText = isSuspended
        ? 'Your access is suspended — contact your gym'
        : isExpired
        ? 'Expired on ${stats.subscriptionEnd ?? ''} — contact your gym to renew'
        : stats.daysRemaining != null
        ? 'Expires ${stats.subscriptionEnd ?? ''} (${stats.daysRemaining} days)'
        : 'No active subscription';

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
                  style: TextStyle(color: subTextColor, fontSize: 12),
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
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
          ColorFiltered(
            colorFilter: earned
                ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                : const ColorFilter.matrix(<double>[
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
            child: Opacity(
              opacity: earned ? 1.0 : 0.4,
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
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
}
