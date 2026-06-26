import 'package:flutter/material.dart';
import '../controllers/coach_schedule_controller.dart';

class RecurringSwitchField extends StatelessWidget {
  final CoachScheduleController ctrl;

  const RecurringSwitchField({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recurring (weekly)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Switch(
              value: ctrl.isRecurring,
              onChanged: ctrl.setRecurring,
              activeThumbColor: const Color(0xFF4F46E5),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class DatePickerField extends StatelessWidget {
  final CoachScheduleController ctrl;

  const DatePickerField({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    // ── Recurring → show day-of-week dropdown ────────────────────────────────
    if (ctrl.isRecurring) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Day of Week *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: ctrl.selectedDay,
                hint: const Text('Select a day',
                    style: TextStyle(color: Colors.grey)),
                isExpanded: true,
                items: ctrl.days.map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text(
                      // Capitalize first letter for display
                      day[0].toUpperCase() + day.substring(1),
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: ctrl.setDay,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    // ── Non-recurring → show date picker ─────────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Start Date *',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              ctrl.setDate(
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
              );
            }
          },
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ctrl.selectedDate ?? 'Pick a date',
                  style: TextStyle(
                      color: ctrl.selectedDate != null
                          ? Colors.black
                          : Colors.grey),
                ),
                const Icon(Icons.calendar_today,
                    size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class TimePickerField extends StatelessWidget {
  final CoachScheduleController ctrl;

  const TimePickerField({super.key, required this.ctrl});

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final min = parts[1];
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    return '${h.toString().padLeft(2, '0')}:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Time *',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
                context: context, initialTime: TimeOfDay.now());
            if (picked != null) {
              ctrl.setTime(
                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00');
            }
          },
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ctrl.selectedTime != null
                      ? _formatTime(ctrl.selectedTime!)
                      : 'Pick a time',
                  style: TextStyle(
                      color: ctrl.selectedTime != null
                          ? Colors.black
                          : Colors.grey),
                ),
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}