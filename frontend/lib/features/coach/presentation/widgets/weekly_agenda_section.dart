import 'package:flutter/material.dart';
import '../controllers/coach_schedule_controller.dart';
import '../../domain/coach_schedule_model.dart';
import '../widgets/coach_ui_utils.dart';

class WeeklyAgendaSection extends StatelessWidget {
  final CoachScheduleController ctrl;

  const WeeklyAgendaSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.weekly.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This Week\'s Agenda',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ctrl.weekly.map((day) => _WeeklyDayItem(day: day)).toList(),
          ),
        ),
      ],
    );
  }
}

class _WeeklyDayItem extends StatelessWidget {
  final CoachWeeklyDayModel day;

  const _WeeklyDayItem({required this.day});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4, left: 4, right: 12),
                decoration: BoxDecoration(
                  color: CoachColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: CoachColors.primary.withValues(alpha: 0.3), width: 3),
                ),
              ),
              Text(
                capitalizeDay(day.day),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (day.classes.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                'No classes scheduled',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            )
          else
            ...day.classes.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          '${c.currentClients}/${c.maxClients} booked',
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: CoachColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          formatTime(c.startTime),
                          style: const TextStyle(color: CoachColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        if (c.gymName != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(c.gymName!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }
}