import 'package:flutter/material.dart';
import 'package:frontend/features/admin/domain/schedule_model.dart';
import 'package:provider/provider.dart';
import '../controllers/gym_schedule_controller.dart';
import 'coach_ui_utils.dart';
import 'coach_dashboard_screen.dart';
import '../widgets/coach_bottom_nav.dart';

class GymScheduleScreen extends StatefulWidget {
  final String token;
  final int gymId;
  final String gymName;

  const GymScheduleScreen({super.key, required this.token, required this.gymId, required this.gymName});

  @override
  State<GymScheduleScreen> createState() => _GymScheduleScreenState();
}

class _GymScheduleScreenState extends State<GymScheduleScreen> {
  late final GymScheduleController _ctrl;
  static const _dayOrder = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

  @override
  void initState() {
    super.initState();
    _ctrl = GymScheduleController();
    _ctrl.loadGymSchedule(widget.token, widget.gymId);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<GymScheduleController>(
        builder: (context, ctrl, _) {
          final grouped = _groupByDay(ctrl.classes);

          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.gymName} — Schedule',
                    style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text('Weekly class timetable', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            body: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => ctrl.loadGymSchedule(widget.token, widget.gymId),
                    child: ctrl.classes.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              EmptyState(
                                title: 'No classes scheduled',
                                subtitle: 'This gym has no classes on the timetable yet.',
                                icon: Icons.calendar_month_outlined,
                              ),
                            ],
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            children: [
                              const Text('Weekly Timetable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('All classes at this gym', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(height: 16),
                              for (final entry in grouped.entries) _buildDayCard(entry.key, entry.value),
                            ],
                          ),
                  ),
            bottomNavigationBar: CustomBottomNav(
              currentIndex: 2, // 2 = Gyms Tab
              onTap: (i) {
                if (i == 2) {
                  Navigator.pop(context);
                } else {
                  // Jump to Dashboard and switch to the selected tab
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CoachDashboardScreen(
                        token: widget.token, 
                        initialIndex: i,
                      ),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

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

  Widget _buildDayCard(String dayKey, List<ClassSessionModel> classes) {
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
            _buildClassRow(classes[i]),
            if (i != classes.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildClassRow(ClassSessionModel c) {
    final isFull = c.currentClients >= c.maxClients;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: 40,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(color: CoachColors.primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 13, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  // NOTE: assumes ClassSessionModel has a `duration` (minutes)
                  // and `coachName` field, matching the admin schedule model.
                  // Rename below if your field names differ.
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
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isFull ? CoachColors.danger : Colors.grey.shade800),
          ),
        ),
      ],
    );
  }
}