import 'package:flutter/material.dart';
import '../admin/presentation/client_management_screen.dart';
import '../admin/presentation/admin_profile.dart';



class AdminBottomBar extends StatelessWidget {
  final int currentIndex, gymId;
  final String token;

  const AdminBottomBar({
    super.key,
    required this.currentIndex,
    required this.token,
    required this.gymId,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.dashboard, 'Dashboard'),
      (Icons.people_outline, 'Clients'),
      (Icons.calendar_today, 'Schedule'),
      (Icons.person_outline, 'Profile'),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final active = index == currentIndex;

          return Expanded(
              child: GestureDetector(
                onTap: () => _onTap(context, index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.$1,
                    color: active? const Color(0xFF4F46E5) : Colors.grey,
                    size: 24,),
                    const SizedBox(height: 3,),
                    Text(item.$2,
                      style: TextStyle(
                        fontSize: 10,
                        color: active? const Color(0xFF4F46E5) : Colors.grey,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal
                      )),
                  ],
                ),
              ),
          );
        }).toList(),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pop(context);
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ClientManagementScreen(gymId: gymId, token: token),
        ));
        break;
      case 2:
        // TODO: Schedule screen
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(
        builder: (_) => AdminProfileScreen(gymId: gymId, token: token)));
        break;
    }
  }

}