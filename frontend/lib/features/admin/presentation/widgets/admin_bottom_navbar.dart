// lib/features/admin/presentation/admin_shell.dart

import 'package:flutter/material.dart';
import '../admin_schedule_screen.dart';
import '../gym_dashboard_screen.dart';
import '../admin_profile.dart';
import '../analytics_screen.dart';
import '../../data/gym_repository.dart';

class AdminShell extends StatefulWidget {
  final String token;
  final GymModel gym;

  const AdminShell({super.key, required this.token, required this.gym});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  final _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        Navigator(
          key: _navigatorKeys[0],
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => GymDashboardScreen(
              token: widget.token,
              gym: widget.gym,
              onTabChange: _onTap,
            ),
          ),
        ),
        Navigator(
          key: _navigatorKeys[1],
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => AnalyticsScreen(
              token: widget.token,
              gymId: widget.gym.gymID,
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

  void _onTap(int index) {
    if (index == _currentIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _currentIndex = index);
  }
}