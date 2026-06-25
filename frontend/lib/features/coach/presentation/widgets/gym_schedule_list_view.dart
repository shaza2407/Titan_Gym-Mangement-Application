import 'package:flutter/material.dart';
import '../../../admin/domain/schedule_model.dart';
import '../../presentation/controllers/gym_schedule_controller.dart';
import 'coach_ui_utils.dart';
import 'day_schedule_card.dart';

class GymScheduleListView extends StatelessWidget {
  final GymScheduleController ctrl;

  const GymScheduleListView({super.key, required this.ctrl});

  static const _dayOrder = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

  Map<String, List<ClassSessionModel>> _groupByDay(List<ClassSessionModel> classes) {
    final Map<String, List<ClassSessionModel>> grouped = {};

    for (final c in classes) {
      final key = c.isRecurring ? (c.dayOfWeek ?? '').toLowerCase() : _weekdayFromDate(c.date);
      if (key.isEmpty) continue;
      grouped.putIfAbsent(key, () => []).add(c);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => _dayOrder.indexOf(a).compareTo(_dayOrder.indexOf(b)));
    return {for (final k in sortedKeys) k: grouped[k]!};
  }

  String _weekdayFromDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      return _dayOrder[DateTime.parse(dateStr).weekday - 1];
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ctrl.classes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          EmptyState(
            title: 'No classes scheduled',
            subtitle: 'This gym has no classes on the timetable yet.',
            icon: Icons.calendar_month_outlined,
          ),
        ],
      );
    }

    final grouped = _groupByDay(ctrl.classes);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Weekly Timetable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('All classes at this gym', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),
        for (final entry in grouped.entries) DayScheduleCard(dayKey: entry.key, classes: entry.value),
      ],
    );
  }
}