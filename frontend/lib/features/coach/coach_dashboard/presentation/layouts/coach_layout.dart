import 'package:flutter/material.dart';
import 'package:frontend/features/coach/coach_dashboard/presentation/screens/coach_dashboard_screen.dart';
import 'package:frontend/features/coach/coach_profile/coach_profile_screen.dart';
import 'package:frontend/features/coach/coach_schedule/presentation/screens/coach_schedule_screen.dart';
import 'package:frontend/features/coach/shared/presentation/coach_bottom_nav.dart';

// Import your screens

class CoachMainWrapper extends StatefulWidget {
  final int coachId; // Pass the logged-in coach ID here
  const CoachMainWrapper({super.key, required this.coachId});

  @override
  State<CoachMainWrapper> createState() => _CoachMainWrapperState();
}

class _CoachMainWrapperState extends State<CoachMainWrapper> {
  int _currentIndex = 0;

  // List of all the screens the BottomNavBar will switch between
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      CoachDashboardScreen(coachId: widget.coachId),
      CoachScheduleScreen(
        coachId: widget.coachId,
        onBack: () => setState(() => _currentIndex = 0),
      ),
      const Center(child: Text("Gyms Page Coming Soon")),
      CoachProfileScreen(onBack: () => setState(() => _currentIndex = 0)),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      // 2. The Body (swaps out seamlessly)
      // IndexedStack preserves the state of your tabs so they don't reload!
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // 3. The Global Bottom Navigation Bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}