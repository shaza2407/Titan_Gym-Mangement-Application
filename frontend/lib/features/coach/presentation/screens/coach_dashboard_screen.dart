import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/notifications/notification_badge_controller.dart';
import '../../../notification/token_helper.dart';
import '../controllers/coach_dashboard_controller.dart';
import '../controllers/coach_schedule_controller.dart';
import '../controllers/coach_gyms_controller.dart';
import '../controllers/coach_profile_controller.dart';
import '../widgets/coach_ui_utils.dart';
import 'coach_schedule_screen.dart';
import 'coach_profile_screen.dart';
import 'coach_gyms_screen.dart';

// --- Import widgets ---
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_stats_row.dart';
import '../widgets/upcoming_classes_section.dart';
import '../widgets/quick_actions_section.dart';

class CoachDashboardScreen extends StatefulWidget {
  final String token;
  final int initialIndex;

  const CoachDashboardScreen({
    super.key,
    required this.token,
    this.initialIndex = 0,
  });

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  int _currentIndex = 0;

  // All controllers owned here — no GlobalKey needed
  late final CoachDashboardController _dashboardCtrl;
  late final CoachScheduleController _scheduleCtrl;
  late final CoachGymsController _gymsCtrl;
  late final CoachProfileController _profileCtrl;
  late final NotificationBadgeController _badgeCtrl;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _dashboardCtrl = CoachDashboardController()..loadAll(widget.token);
    _scheduleCtrl  = CoachScheduleController()..loadAll(widget.token);
    _gymsCtrl      = CoachGymsController()..loadAll(widget.token);
    _profileCtrl   = CoachProfileController()..loadProfile(widget.token);

    _badgeCtrl = NotificationBadgeController()
      ..load(widget.token, getUserIdFromToken(widget.token));
  }

  @override
  void dispose() {
    _dashboardCtrl.dispose();
    _scheduleCtrl.dispose();
    _gymsCtrl.dispose();
    _profileCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  /// Re-fetches data for whichever tab is being switched to.
  void _onTabTap(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        _dashboardCtrl.loadAll(widget.token);
        _badgeCtrl.load(widget.token, getUserIdFromToken(widget.token));
        break;
      case 1:
        _scheduleCtrl.loadAll(widget.token);
        break;
      case 2:
        _gymsCtrl.loadAll(widget.token);
        break;
      case 3:
        _profileCtrl.loadProfile(widget.token);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _badgeCtrl,
      child: Scaffold(
        backgroundColor: CoachColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Tab 0 — Dashboard
            ChangeNotifierProvider.value(
              value: _dashboardCtrl,
              child: Consumer<CoachDashboardController>(
                builder: (context, ctrl, _) => _buildHomeTab(ctrl),
              ),
            ),

            // Tab 1 — Schedule
            CoachScheduleScreen(
              token: widget.token,
              controller: _scheduleCtrl,
              onBack: () => _onTabTap(0),
            ),

            // Tab 2 — Gyms
            CoachGymsScreen(
              token: widget.token,
              controller: _gymsCtrl,
              onBack: () => _onTabTap(0),
            ),

            // Tab 3 — Profile
            CoachProfileScreen(
              token: widget.token,
              controller: _profileCtrl,
              onBack: () => _onTabTap(0),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTabTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: CoachColors.primary,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), label: 'Gyms'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }

  Widget _buildHomeTab(CoachDashboardController ctrl) {
    if (ctrl.isLoading && ctrl.stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _dashboardCtrl.loadAll(widget.token),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHeader(token: widget.token, badgeCtrl: _badgeCtrl),
              const SizedBox(height: 16),
              DashboardStatsRow(stats: ctrl.stats),
              const SizedBox(height: 16),
              UpcomingClassesSection(ctrl: ctrl),
              const SizedBox(height: 16),
              QuickActionsSection(
                ctrl: ctrl,
                token: widget.token,
                onTabChange: (index) => _onTabTap(index),
              ),
            ],
          ),
        ),
      ),
    );
  }
}