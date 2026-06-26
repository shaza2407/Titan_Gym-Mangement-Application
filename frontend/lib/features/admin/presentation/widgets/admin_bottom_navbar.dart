import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/admin_schedule_screen.dart';
import '../screens/gym_dashboard_screen.dart';
import '../screens/admin_profile.dart';
import '../screens/analytics_screen.dart';
import '../../domain/gym_model.dart';
import '../controller/gym_dashboard_controller.dart';
import '../controller/admin_schedule_controller.dart';
import '../controller/analytics_controller.dart';
import '../controller/admin_profile_controller.dart';

class AdminShell extends StatefulWidget {
  final String token;
  final GymModel gym;

  const AdminShell({super.key, required this.token, required this.gym});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  // All controllers owned here
  late final GymDashboardController _dashboardController;
  late final AdminScheduleController _scheduleController;
  late final AnalyticsController _analyticsController;
  late final AdminProfileController _profileController;

  final _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _dashboardController = GymDashboardController();
    _scheduleController  = AdminScheduleController()..loadAll(widget.token, widget.gym.gymID);
    _analyticsController = AnalyticsController()..loadAll(widget.token, widget.gym.gymID);
    _profileController = AdminProfileController()..loadProfile(widget.token);
  }

  @override
  void dispose() {
    _dashboardController.dispose();
    _scheduleController.dispose();
    _analyticsController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _currentIndex) {
      // Same tab tapped — pop to root and refresh
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    }

    setState(() => _currentIndex = index);

    // Reload data for the tab being switched to
    switch (index) {
      case 0:
        _dashboardController.loadDashboardStats(token: widget.token, gymId: widget.gym.gymID);
        break;
      case 1:
        _analyticsController.loadAll(widget.token, widget.gym.gymID);
        break;
      case 2:
        _scheduleController.loadAll(widget.token, widget.gym.gymID);
        break;
      case 3:
        _profileController.loadProfile(widget.token);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _dashboardController,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (_navigatorKeys[_currentIndex].currentState?.canPop() == true) {
              _navigatorKeys[_currentIndex].currentState?.pop();
            }
          },
          child: _buildBody(),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        Navigator(
          key: _navigatorKeys[0],
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider.value(
              value: _dashboardController,
              child: GymDashboardScreen(
                token: widget.token,
                gym: widget.gym,
                onTabChange: _onTap,
              ),
            ),
          ),
        ),
        Navigator(
          key: _navigatorKeys[1],
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => AnalyticsScreen(
              token: widget.token,
              gymId: widget.gym.gymID,
              controller: _analyticsController,
              onTabChange: _onTap,
            ),
          ),
        ),
        Navigator(
          key: _navigatorKeys[2],
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => AdminScheduleScreen(
              token: widget.token,
              gymId: widget.gym.gymID,
              controller: _scheduleController,
              onTabChange: _onTap,
            ),
          ),
        ),
        Navigator(
          key: _navigatorKeys[3],
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => AdminProfileScreen(
              token: widget.token,
              gymId: widget.gym.gymID,
              controller: _profileController,
              onTabChange: _onTap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF4F46E5),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.insert_chart_outlined),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          label: 'Schedule',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}