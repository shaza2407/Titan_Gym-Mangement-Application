import 'package:flutter/material.dart';
import 'package:frontend/features/coach/coach_dashboard/presentation/screens/coach_dashboard_screen.dart';
import 'package:frontend/features/coach/coach_profile/coach_profile_screen.dart';
import 'package:frontend/features/coach/coach_schedule/presentation/screens/coach_schedule_screen.dart';
import 'package:frontend/features/coach/shared/presentation/coach_bottom_nav.dart';

class CoachMainWrapper extends StatefulWidget {
  final String token;
  const CoachMainWrapper({super.key, required this.token});

  @override
  State<CoachMainWrapper> createState() => _CoachMainWrapperState();
}

class _CoachMainWrapperState extends State<CoachMainWrapper> {
  int _currentIndex = 0;
  int _scheduleRefreshCounter = 0;

  late final List<Widget> _pages;

  void _refreshScheduleStats() {
    setState(() {
      _scheduleRefreshCounter++;
      _pages[1] = CoachScheduleScreen(
        token: widget.token,
        refreshCounter: _scheduleRefreshCounter,
        onStatsRefreshNeeded: _refreshScheduleStats,
        onBack: () => setState(() => _currentIndex = 0),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      CoachDashboardScreen(token: widget.token),
      CoachScheduleScreen(
        token: widget.token,
        refreshCounter: _scheduleRefreshCounter,
        onStatsRefreshNeeded: _refreshScheduleStats,
        onBack: () => setState(() => _currentIndex = 0),
      ),
      const Center(child: Text("Gyms Page Coming Soon")),
      CoachProfileScreen(
        token: widget.token,
        onBack: () => setState(() => _currentIndex = 0),
      ),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 1) {
        _scheduleRefreshCounter++;
        _pages[1] = CoachScheduleScreen(
          token: widget.token,
          refreshCounter: _scheduleRefreshCounter,
          onStatsRefreshNeeded: _refreshScheduleStats,
          onBack: () => setState(() => _currentIndex = 0),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 2. The Body (swaps out seamlessly)
      // IndexedStack preserves the state of your tabs so they don't reload!
      body: IndexedStack(index: _currentIndex, children: _pages),

      // 3. The Global Bottom Navigation Bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
