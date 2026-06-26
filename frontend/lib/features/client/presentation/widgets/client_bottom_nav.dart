import 'package:flutter/material.dart';

class ClientBottomNav extends StatelessWidget {
  final int currentIndex; // -1 = no tab highlighted
  final ValueChanged<int> onTap;

  const ClientBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // BottomNavigationBar requires a valid index, so clamp to 0 when none selected
    final displayIndex = currentIndex < 0 ? 0 : currentIndex;

    return BottomNavigationBar(
      currentIndex: displayIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: currentIndex < 0
          ? Colors.grey 
          : const Color(0xFF4F46E5),
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
}