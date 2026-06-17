import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin/presentation/admin_profile.dart';
import '../admin/presentation/gym_dashboard_screen.dart';
import '../admin/data/gym_repository.dart';
import '../admin/controller/admin_gym_controller.dart';

class AdminBottomBar extends StatelessWidget {
  final int currentIndex;
  final String token;
   final GymModel gym;

  const AdminBottomBar({
    super.key,
    required this.currentIndex,
    required this.token,
    required this.gym,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.dashboard, 'Dashboard'),
      (Icons.bar_chart_rounded, 'Analytics'),
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
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => AdminGymController(),
          child: GymDashboardScreen(token: token, gym: gym),
        ),
      ));
      break;
      case 1:
        // TODO: Analytics screen
        break;
      case 2:
        // TODO: Schedule screen
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(
        builder: (_) => AdminProfileScreen(gymId: gym.gymID, token: token)));
        break;
    }
  }

}