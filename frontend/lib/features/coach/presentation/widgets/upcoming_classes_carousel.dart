import 'package:flutter/material.dart';
import '../controllers/coach_schedule_controller.dart';
import '../../domain/coach_schedule_model.dart';
import '../widgets/coach_ui_utils.dart';
// import 'coach_ui_utils.dart';

class UpcomingClassesCarousel extends StatelessWidget {
  final CoachScheduleController ctrl;
  final String token;

  const UpcomingClassesCarousel({super.key, required this.ctrl, required this.token});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Active Classes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 16),
        if (ctrl.myClasses.isEmpty)
          const EmptyState(title: 'No classes', subtitle: 'You have no assigned classes.')
        else
          SizedBox(
            height: 150,
            child: Stack(
              children: [
                ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ctrl.myClasses.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (context, index) => _CompactClassCard(
                    classModel: ctrl.myClasses[index],
                    ctrl: ctrl,
                    token: token,
                  ),
                ),
                if (ctrl.myClasses.length > 1)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [CoachColors.background.withValues(alpha: 0), CoachColors.background],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CompactClassCard extends StatelessWidget {
  final CoachClassModel classModel;
  final CoachScheduleController ctrl;
  final String token;

  const _CompactClassCard({required this.classModel, required this.ctrl, required this.token});

  @override
  Widget build(BuildContext context) {
    final isFull = classModel.currentClients >= classModel.maxClients;
    final capacityColor = isFull ? CoachColors.danger : CoachColors.success;

    String displayDate = 'TBD';
    if (classModel.isRecurring && classModel.dayOfWeek != null && classModel.dayOfWeek!.isNotEmpty) {
      displayDate = capitalizeDay(classModel.dayOfWeek);
    } else if (classModel.date != null && classModel.date!.isNotEmpty) {
      displayDate = formatDate(classModel.date!);
    } else if (classModel.dayOfWeek != null && classModel.dayOfWeek!.isNotEmpty) {
      displayDate = capitalizeDay(classModel.dayOfWeek);
    }

    IconData dateIcon = classModel.isRecurring ? Icons.repeat_rounded : Icons.event_note_outlined;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  classModel.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if ((classModel.date?.isNotEmpty ?? false) || (classModel.dayOfWeek?.isNotEmpty ?? false)) ...[
                Icon(dateIcon, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(displayDate, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ],
              const SizedBox(width: 12),
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                formatTime(classModel.startTime),
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  classModel.gymName ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: capacityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people, color: capacityColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${classModel.currentClients}/${classModel.maxClients}',
                      style: TextStyle(color: capacityColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}