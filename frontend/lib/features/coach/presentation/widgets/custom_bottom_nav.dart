// widgets/custom_bottom_nav.dart

import 'package:flutter/material.dart';
import 'coach_ui_utils.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex; // -1 = no tab highlighted
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayIndex = currentIndex < 0 ? 0 : currentIndex;

    return BottomNavigationBar(
      currentIndex: displayIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: currentIndex < 0 ? Colors.grey : CoachColors.primary,
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
          icon: Icon(Icons.fitness_center_outlined),
          label: 'Gyms',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}