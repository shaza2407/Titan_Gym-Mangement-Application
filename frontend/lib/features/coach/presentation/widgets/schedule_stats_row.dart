import 'package:flutter/material.dart';
import '../controllers/coach_schedule_controller.dart';
import '../widgets/coach_ui_utils.dart'; // Adjust path if needed

class ScheduleStatsRow extends StatelessWidget {
  final CoachScheduleController ctrl;

  const ScheduleStatsRow({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StatCard(
          icon: Icons.calendar_today_outlined,
          value: '${ctrl.stats?.weeklyClasses ?? 0}',
          label: 'Weekly\nClasses',
          color: CoachColors.primary,
        ),
        const SizedBox(width: 12),
        StatCard(
          icon: Icons.people_outline,
          value: '${ctrl.stats?.totalClients ?? 0}',
          label: 'Total\nClients',
          color: CoachColors.success,
        ),
        const SizedBox(width: 12),
        StatCard(
          icon: Icons.access_time_outlined,
          value: '${ctrl.stats?.pendingRequests ?? 0}',
          label: 'Pending\nRequests',
          color: CoachColors.warning,
        ),
      ],
    );
  }
}