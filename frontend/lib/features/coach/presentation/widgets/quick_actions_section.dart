import 'package:flutter/material.dart';
import '../../presentation/controllers/coach_dashboard_controller.dart';
import '../../presentation/controllers/coach_schedule_controller.dart';
import '../../presentation/screens/request_class_screen.dart';
import 'quick_action_item.dart';

class QuickActionsSection extends StatelessWidget {
  final CoachDashboardController ctrl;
  final String token;
  final Function(int) onTabChange;

  const QuickActionsSection({
    super.key,
    required this.ctrl,
    required this.token,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Manage your coaching activities',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          QuickActionItem(
            icon: Icons.business,
            title: 'My Gyms',
            subtitle: 'View gyms you are coaching at',
            onTap: () => onTabChange(2),
          ),
          QuickActionItem(
            icon: Icons.calendar_month_outlined,
            title: 'Request Class',
            subtitle: 'Open a request to add a new class',
            onTap: () async {
              final scheduleCtrl = CoachScheduleController();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestClassScreen(
                    token: token,
                    controller: scheduleCtrl,
                  ),
                ),
              );
              ctrl.loadAll(token);
            },
          ),
          QuickActionItem(
            icon: Icons.person_outline,
            title: 'My Profile',
            subtitle: 'Update your coach information',
            onTap: () => onTabChange(3),
          ),
        ],
      ),
    );
  }
}