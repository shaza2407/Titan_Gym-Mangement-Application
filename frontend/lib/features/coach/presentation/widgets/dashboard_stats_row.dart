import 'package:flutter/material.dart';
import 'coach_ui_utils.dart';

class DashboardStatsRow extends StatelessWidget {
  final dynamic
  stats; // Replace 'dynamic' with your actual Stats Model type (e.g., CoachDashboardStatsModel)

  const DashboardStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StatCard(
          icon: Icons.calendar_today_outlined,
          value: '${stats?.weeklyClasses ?? 0}',
          label: 'Weekly\nClasses',
          color: CoachColors.primary,
        ),
        const SizedBox(width: 12),
        StatCard(
          icon: Icons.people_outline,
          value: '${stats?.totalClients ?? 0}',
          label: 'Total\nClients',
          color: CoachColors.success,
        ),
        const SizedBox(width: 12),
        StatCard(
          icon: Icons.fitness_center_outlined,
          value: '${stats?.activeGyms ?? 0}',
          label: 'Active\nGyms',
          color: CoachColors.warning,
        ),
      ],
    );
  }
}
