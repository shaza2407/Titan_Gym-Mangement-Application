import 'package:flutter/material.dart';
import '../controllers/coach_schedule_controller.dart';
import '../widgets/coach_ui_utils.dart';

class ScheduleTabs extends StatelessWidget {
  final CoachScheduleController ctrl;
  final void Function(int)? onTabChanged;

  const ScheduleTabs({
    super.key,
    required this.ctrl,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: CoachColors.cardBorder, width: 2)),
      ),
      child: Row(
        children: [
          _ScheduleTab(
            label: 'Overview',
            index: 0,
            selectedIndex: ctrl.selectedTab,
            onTap: () {
              onTabChanged != null ? onTabChanged!(0) : ctrl.setTab(0);
            },
          ),
          _ScheduleTab(
            label: 'My Requests',
            index: 1,
            selectedIndex: ctrl.selectedTab,
            badge: ctrl.stats?.pendingRequests,
            onTap: () {
              onTabChanged != null ? onTabChanged!(1) : ctrl.setTab(1);
            },
          ),
        ],
      ),
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  final String label;
  final int index;
  final int selectedIndex;
  final int? badge;
  final VoidCallback onTap;

  const _ScheduleTab({
    required this.label,
    required this.index,
    required this.selectedIndex,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: selected ? Colors.black : Colors.transparent,
                  width: 2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 15,
                  color: selected ? Colors.black : Colors.grey.shade500,
                ),
              ),
              if (badge != null && badge! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: CoachColors.warning,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}