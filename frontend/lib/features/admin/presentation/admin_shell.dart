// lib/features/admin/presentation/admin_shell.dart

import 'package:flutter/material.dart';
import 'gym_dashboard_screen.dart';
import 'client_management_screen.dart';
import 'admin_profile.dart';
import 'analytics_screen.dart';
import '../data/gym_repository.dart';

class AdminShell extends StatefulWidget {
  final String token;
  final GymModel gym;

  const AdminShell({super.key, required this.token, required this.gym});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return GymDashboardScreen(
          token: widget.token,
          gym: widget.gym,
          onTabChange: _onTap,        
        );
      case 1:
        return AnalyticsScreen(
          token: widget.token,
          gymId: widget.gym.gymID,
          onTabChange: _onTap,
        );
      case 2:
        return const Center(child: Text('Schedule - Coming Soon'));
      case 3:
        return AdminProfileScreen(
          token: widget.token,
          gymId: widget.gym.gymID,
          onTabChange: _onTap,);
      default:
        return GymDashboardScreen(
          token: widget.token,
          gym: widget.gym,
          onTabChange: _onTap,
        );
    }
  }

  Widget _buildBottomBar() {
    final items = [
      (Icons.dashboard_outlined, 'Dashboard'),
      (Icons.insert_chart_outlined, 'Analytics'),
      (Icons.calendar_today_outlined, 'Schedule'),
      (Icons.person_outline, 'Profile'),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final active = index == _currentIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => _onTap(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$1,
                      color: active ? const Color(0xFF4F46E5) : Colors.grey,
                      size: 24),
                  const SizedBox(height: 3),
                  Text(item.$2,
                      style: TextStyle(
                        fontSize: 10,
                        color: active ? const Color(0xFF4F46E5) : Colors.grey,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }
}