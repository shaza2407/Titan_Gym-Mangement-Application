// lib/features/client/presentation/screens/client_schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/client_schedule_controller.dart';
import '../../domain/schedule_model.dart';

class ClientScheduleScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onBack;
  const ClientScheduleScreen({super.key, required this.token, this.onBack});

  @override
  State<ClientScheduleScreen> createState() => _ClientScheduleScreenState();
}

class _ClientScheduleScreenState extends State<ClientScheduleScreen> {
  late ClientScheduleController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ClientScheduleController();
    _ctrl.loadAll(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<ClientScheduleController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFFF3F4F6),
              body: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
            );
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF3F4F6), // Light theme
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              automaticallyImplyLeading: false,
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: widget.onBack,
                    )
                  : null,
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gym Timetable',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'View and enroll in active gym sessions',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Stats ─────────────────────────────────────────
                  _buildStats(ctrl),
                  const SizedBox(height: 16),

                  // ── Tabs ──────────────────────────────────────────
                  _buildTabs(ctrl),
                  const SizedBox(height: 16),

                  // ── Tab Content ───────────────────────────────────
                  if (ctrl.selectedTab == 0) _buildMyClasses(ctrl),
                  if (ctrl.selectedTab == 1) _buildBrowse(ctrl),

                  // ── Weekly Schedule ───────────────────────────────
                  _buildWeekly(ctrl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  Widget _buildStats(ClientScheduleController ctrl) {
    return Row(
      children: [
        _buildStatCard(
          Icons.calendar_today_outlined,
          '${ctrl.stats?.enrolled ?? 0}',
          'Enrolled Classes',
          const Color(0xFF4F46E5),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          Icons.check_circle_outline,
          '${ctrl.stats?.classesThisMonth ?? 0}',
          'Completed\nThis Month',
          const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────
  Widget _buildTabs(ClientScheduleController ctrl) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab(ctrl, 0, 'My Classes'),
          _buildTab(ctrl, 1, 'Browse All'),
        ],
      ),
    );
  }

  Widget _buildTab(ClientScheduleController ctrl, int index, String label) {
    final selected = ctrl.selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => ctrl.setTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: selected ? const Color(0xFF4F46E5) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  // ── My Classes ────────────────────────────────────────────────────────────
  Widget _buildMyClasses(ClientScheduleController ctrl) {
    if (ctrl.myClasses.isEmpty) {
      return _buildEmpty('No classes enrolled yet', 'Browse active timetable to sign up');
    }
    return Column(
      children: ctrl.myClasses.map((c) => _buildMyClassCard(ctrl, c)).toList(),
    );
  }

  Widget _buildMyClassCard(ClientScheduleController ctrl, ClassModel c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            c.coachName != null ? 'Coach: ${c.coachName}' : 'Gym Class',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(_capitalizeDay(c.dayOfWeek) ?? c.date ?? ''),
              _buildChip(_formatTime(c.startTime)),
              _buildChip('${c.duration} min'),
            ],
          ),
          if (c.nextDate != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Color(0xFF4F46E5),
                ),
                const SizedBox(width: 6),
                Text(
                  'Next Session: ${c.nextDate}',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await _showConfirm(
                  'Unenroll',
                  'Are you sure you want to cancel your enrollment in ${c.title}?',
                );
                if (confirm == true) {
                  final success = await ctrl.unenroll(
                    widget.token,
                    c.id,
                    c.nextDate ?? '',
                  );
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Unenrolled successfully')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.close, size: 16, color: Colors.red),
              label: const Text(
                'Cancel Enrollment',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Browse ────────────────────────────────────────────────────────────────
  Widget _buildBrowse(ClientScheduleController ctrl) {
    return Column(
      children: [
        // Day filter
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ctrl.days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final day = ctrl.days[i];
              final selected = (ctrl.selectedDay ?? 'All') == day;
              return GestureDetector(
                onTap: () => ctrl.filterByDay(widget.token, day),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF4F46E5) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? const Color(0xFF4F46E5) : const Color(0xFFD1D5DB),
                    ),
                  ),
                  child: Text(
                    day == 'All'
                        ? 'All Days'
                        : day[0].toUpperCase() + day.substring(1, 3),
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        if (ctrl.isBrowseLoading)
          const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
        else if (ctrl.browseClasses.isEmpty)
          _buildEmpty('No classes scheduled', 'Try searching for another day')
        else
          ...ctrl.browseClasses.map((c) => _buildBrowseCard(ctrl, c)),
      ],
    );
  }

  Widget _buildBrowseCard(ClientScheduleController ctrl, ClassModel c) {
    final ratio = c.maxClients > 0 ? (c.currentClients / c.maxClients) : 0.0;
    final capacityColor = c.isFull
        ? Colors.red
        : ratio > 0.8
        ? Colors.orange
        : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  c.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: capacityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: capacityColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people, color: capacityColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${c.currentClients}/${c.maxClients}',
                      style: TextStyle(color: capacityColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF4F46E5),
              ),
              const SizedBox(width: 4),
              Text(
                _capitalizeDay(c.dayOfWeek) ?? '',
                style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.access_time, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                '${_formatTime(c.startTime)} (${c.duration} min)',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                'Coach: ${c.coachName ?? 'Gym Instructor'}',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ],
          ),
          if (c.nextDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(
                  'Next Session: ${c.nextDate}',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: c.isFull && !c.isEnrolled
                ? ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5E7EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Session Full',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold),
                    ),
                  )
                : c.isEnrolled
                ? OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await _showConfirm(
                        'Unenroll',
                        'Unenroll from ${c.title}?',
                      );
                      if (confirm == true) {
                        await ctrl.unenroll(
                          widget.token,
                          c.id,
                          c.nextDate ?? '',
                        );
                      }
                    },
                    icon: const Icon(Icons.check, size: 16, color: Color(0xFF4F46E5)),
                    label: const Text('Enrolled (Cancel?)', style: TextStyle(color: Color(0xFF4F46E5))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF4F46E5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () async {
                      final success = await ctrl.enroll(
                        widget.token,
                        c.id,
                        c.nextDate ?? '',
                      );
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Enrolled in ${c.title}!'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      } else if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ctrl.errorMessage ?? 'Enroll failed'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Book Session',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Weekly Schedule ───────────────────────────────────────────────────────
  Widget _buildWeekly(ClientScheduleController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This Week\'s Timetable',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const Text(
                'Weekly overview of your registered workouts',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
              const SizedBox(height: 16),
              if (ctrl.weekly.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                      'No bookings this week',
                      style: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                  ),
                )
              else
                ...ctrl.weekly.map((day) => _buildWeekDay(day)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDay(WeeklyDayModel day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day.label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4F46E5)),
            ),
          ),
          Expanded(
            child: day.classes.isEmpty
                ? const Text(
                    'Rest Day',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontStyle: FontStyle.italic),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: day.classes
                        .map(
                          (c) => Text(
                            '${_formatTime(c.startTime)} - ${c.title}',
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildEmpty(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 40,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirm(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Unenroll', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final min = parts[1];
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour > 12
        ? hour - 12
        : hour == 0
        ? 12
        : hour;
    return '${h.toString().padLeft(2, '0')}:$min $period';
  }

  String? _capitalizeDay(String? day) {
    if (day == null || day.isEmpty) return null;
    return day[0].toUpperCase() + day.substring(1);
  }
}
