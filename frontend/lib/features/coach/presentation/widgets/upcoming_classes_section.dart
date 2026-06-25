import 'package:flutter/material.dart';
import '../../domain/coach_dashboard_model.dart';
import '../../presentation/controllers/coach_dashboard_controller.dart';
import 'coach_ui_utils.dart';
// import '../../../../shared/widgets/empty_state.dart';

class UpcomingClassesSection extends StatelessWidget {
  final CoachDashboardController ctrl;

  const UpcomingClassesSection({super.key, required this.ctrl});

  String _todayLabel() {
    final now = DateTime.now();
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[now.weekday - 1]}, ${months[now.month]} ${now.day}, ${now.year}';
  }

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
            "Today's Classes",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            _todayLabel(),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (ctrl.upcoming.isEmpty)
            const EmptyState(
              title: 'No classes today',
              subtitle: "Nothing on the books for today.",
              icon: Icons.free_breakfast_outlined,
            )
          else
            ...ctrl.upcoming.map((c) => _UpcomingClassCard(classModel: c)),
        ],
      ),
    );
  }
}

// Private helper widget for the card design
class _UpcomingClassCard extends StatelessWidget {
  final CoachUpcomingClassModel classModel;

  const _UpcomingClassCard({required this.classModel});

  @override
  Widget build(BuildContext context) {
    final isFull = classModel.currentClients >= classModel.maxClients;
    final ratio = classModel.maxClients == 0 ? 0.0 : classModel.currentClients / classModel.maxClients;
    final capacityColor = isFull ? CoachColors.danger : (ratio > 0.8 ? CoachColors.warning : CoachColors.success);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_month, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classModel.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        classModel.gymName ?? 'Unknown Gym',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatTime(classModel.startTime),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: capacityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${classModel.currentClients}/${classModel.maxClients}',
                  style: TextStyle(color: capacityColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}