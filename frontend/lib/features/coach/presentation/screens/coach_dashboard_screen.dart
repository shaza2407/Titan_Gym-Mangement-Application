import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/notifications/notification_badge_controller.dart';
import '../../../Services/token_helper.dart';
import '../controllers/coach_dashboard_controller.dart';
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
  late final CoachDashboardController _ctrl;
  late final List<Widget> _tabs;
  late NotificationBadgeController _badgeCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = CoachDashboardController();
    _ctrl.loadAll(widget.token);
    _currentIndex = widget.initialIndex;

    _badgeCtrl = NotificationBadgeController();
    _badgeCtrl.load(widget.token, getUserIdFromToken(widget.token));

    _tabs = [
      ChangeNotifierProvider.value(
        value: _ctrl,
        child: Consumer<CoachDashboardController>(
          builder: (context, ctrl, _) => _buildHomeTab(ctrl),
        ),
      ),
      CoachScheduleScreen(
        token: widget.token,
        onBack: () => setState(() => _currentIndex = 0),
      ),
      CoachGymsScreen(
        token: widget.token,
        onBack: () => setState(() => _currentIndex = 0),
      ),
      CoachProfileScreen(
        token: widget.token,
        onBack: () => setState(() => _currentIndex = 0),
      ),
    ];
  }

  @override
  void dispose() {
    _badgeCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _badgeCtrl,
      child: Scaffold(
        backgroundColor: CoachColors.background,
        body: IndexedStack(index: _currentIndex, children: _tabs),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
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

  // 🌟 Look how clean and readable the main layout is now!
  Widget _buildHomeTab(CoachDashboardController ctrl) {
    if (ctrl.isLoading && ctrl.stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _ctrl.loadAll(widget.token),
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
                onTabChange: (index) => setState(() => _currentIndex = index),
              ),
            ],
          ),
        ),
      ),
    );
  }
}