import 'package:flutter/material.dart';
import '../../../admin/domain/schedule_model.dart';
import 'coach_ui_utils.dart'; 

class DayScheduleCard extends StatelessWidget {
  final String dayKey;
  final List<ClassSessionModel> classes;

  const DayScheduleCard({super.key, required this.dayKey, required this.classes});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(capitalizeDay(dayKey), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (int i = 0; i < classes.length; i++) ...[
            _ClassScheduleRow(c: classes[i]),
            if (i != classes.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ClassScheduleRow extends StatelessWidget {
  final ClassSessionModel c;

  const _ClassScheduleRow({required this.c});

  @override
  Widget build(BuildContext context) {
    final isFull = c.currentClients >= c.maxClients;

    // 🌟 UX FIX: Check if the class date is strictly in the past
    bool isPast = false;
    if (c.date != null && c.date!.isNotEmpty) {
      try {
        final classDate = DateTime.parse(c.date!);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        if (classDate.isBefore(today)) {
          isPast = true;
        }
      } catch (_) {
        // Ignore parsing errors and assume it's an active class
      }
    }

    // 🌟 Wrap the row in Opacity to fade it out if it already happened
    return Opacity(
      opacity: isPast ? 0.4 : 1.0, 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 40,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              // Turn the accent line grey if it's in the past
              color: isPast ? Colors.grey : CoachColors.primary, 
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 14,
                    // Add a strikethrough if it's in the past
                    decoration: isPast ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 13, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('${formatTime(c.startTime)} · ${c.duration} min', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(width: 10),
                    Icon(Icons.person_outline, size: 13, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(c.coachName ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isFull ? CoachColors.danger : Colors.grey.shade300),
            ),
            child: Text(
              '${c.currentClients}/${c.maxClients}',
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold, 
                color: isFull ? CoachColors.danger : Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}