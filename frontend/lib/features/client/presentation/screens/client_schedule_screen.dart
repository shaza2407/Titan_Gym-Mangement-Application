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
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  if (widget.onBack != null) widget.onBack!();
                },
              ),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Schedule',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text('View and manage your classes',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                  if (ctrl.selectedTab == 1) _buildUpcoming(ctrl),
                  if (ctrl.selectedTab == 2) _buildBrowse(ctrl),

                  // ── Weekly Schedule ───────────────────────────────
                  if (ctrl.selectedTab == 0 || ctrl.selectedTab == 1)
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
    return Row(children: [
      _buildStatCard(Icons.calendar_today_outlined,
          '${ctrl.stats?.enrolled ?? 0}', 'Enrolled',
          const Color(0xFF4CAF50)),
      const SizedBox(width: 12),
      _buildStatCard(Icons.access_time_outlined,
          '${ctrl.stats?.upcoming ?? 0}', 'Upcoming',
          const Color(0xFF4F46E5)),
      const SizedBox(width: 12),
      _buildStatCard(Icons.people_outline,
          '${ctrl.stats?.minutesWeek ?? 0}', 'Min/Week',
          const Color(0xFFFF9800)),
    ]);
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────
  Widget _buildTabs(ClientScheduleController ctrl) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        _buildTab(ctrl, 0, 'My Classes'),
        _buildTab(ctrl, 1, 'Upcoming'),
        _buildTab(ctrl, 2, 'Browse'),
      ]),
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
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 13,
                  color: selected ? Colors.black : Colors.grey)),
        ),
      ),
    );
  }

  // ── My Classes ────────────────────────────────────────────────────────────
  Widget _buildMyClasses(ClientScheduleController ctrl) {
    if (ctrl.myClasses.isEmpty) {
      return _buildEmpty('No classes enrolled yet', 'Browse classes to enroll');
    }
    return Column(
      children: ctrl.myClasses
          .map((c) => _buildMyClassCard(ctrl, c))
          .toList(),
    );
  }

  Widget _buildMyClassCard(ClientScheduleController ctrl, ClassModel c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(c.title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        Text(c.coachName ?? '',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [
          _buildChip(c.dayOfWeek ?? c.date ?? ''),
          _buildChip(_formatTime(c.startTime)),
          _buildChip('${c.duration} min'),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirm = await _showConfirm(
                  'Unenroll', 'Are you sure you want to unenroll from ${c.title}?');
              if (confirm == true) {
                final success = await ctrl.unenroll(widget.token, c.id);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unenrolled successfully')),
                  );
                }
              }
            },
            icon: const Icon(Icons.close, size: 16, color: Colors.red),
            label: const Text('Unenroll',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Upcoming ──────────────────────────────────────────────────────────────
  Widget _buildUpcoming(ClientScheduleController ctrl) {
    if (ctrl.upcomingClasses.isEmpty) {
      return _buildEmpty('No upcoming classes', 'Enroll in classes to see them here');
    }
    return Column(
      children: ctrl.upcomingClasses
          .map((c) => _buildUpcomingCard(c))
          .toList(),
    );
  }

  Widget _buildUpcomingCard(ClassModel c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.calendar_month,
              color: Color(0xFF4CAF50)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(c.coachName ?? '',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
                Text(
                  '${c.nextDate ?? c.date ?? ''} • ${_formatTime(c.startTime)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ]),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('${c.duration} min',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  // ── Browse ────────────────────────────────────────────────────────────────
  Widget _buildBrowse(ClientScheduleController ctrl) {
    return Column(children: [
      // Day filter
      SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: ctrl.days.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final day = ctrl.days[i];
            final selected = (ctrl.selectedDay ?? 'All') == day;
            return GestureDetector(
              onTap: () => ctrl.filterByDay(widget.token, day),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selected
                          ? Colors.black
                          : Colors.grey.shade300),
                ),
                child: Text(
                  day == 'All'
                      ? 'All Days'
                      : day[0].toUpperCase() + day.substring(1, 3),
                  style: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),

      if (ctrl.isBrowseLoading)
        const Center(child: CircularProgressIndicator())
      else if (ctrl.browseClasses.isEmpty)
        _buildEmpty('No classes available', 'Try a different day')
      else
        ...ctrl.browseClasses.map((c) => _buildBrowseCard(ctrl, c)),
    ]);
  }

  Widget _buildBrowseCard(ClientScheduleController ctrl, ClassModel c) {
    final capacityColor = c.isFull
        ? Colors.red
        : c.currentClients / c.maxClients > 0.8
            ? Colors.orange
            : const Color(0xFF4CAF50);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(c.title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          if (c.isEnrolled)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text('Enrolled',
                    style:
                        TextStyle(color: Colors.white, fontSize: 11)),
              ]),
            ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: capacityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(Icons.people, color: capacityColor, size: 14),
              const SizedBox(width: 4),
              Text('${c.currentClients}/${c.maxClients}',
                  style: TextStyle(
                      color: capacityColor, fontSize: 12)),
            ]),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          '${_capitalizeDay(c.dayOfWeek)}  •  ${_formatTime(c.startTime)} (${c.duration} min)',
          style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 13),
        ),
        Text('Coach: ${c.coachName ?? ''}',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: c.isFull && !c.isEnrolled
              ? ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Full',
                      style: TextStyle(color: Colors.white)),
                )
              : c.isEnrolled
                  ? OutlinedButton(
                      onPressed: () async {
                        final confirm = await _showConfirm('Unenroll',
                            'Unenroll from ${c.title}?');
                        if (confirm == true) {
                          await ctrl.unenroll(widget.token, c.id);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Unenroll'),
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        final success =
                            await ctrl.enroll(widget.token, c.id);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Enrolled in ${c.title}!'),
                              backgroundColor: const Color(0xFF4CAF50),
                            ),
                          );
                        } else if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  ctrl.errorMessage ?? 'Enroll failed'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Enroll',
                          style: TextStyle(color: Colors.white)),
                    ),
        ),
      ]),
    );
  }

  // ── Weekly Schedule ───────────────────────────────────────────────────────
  Widget _buildWeekly(ClientScheduleController ctrl) {
    if (ctrl.weekly.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This Week\'s Schedule',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('Your weekly class calendar',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              ...ctrl.weekly.map((day) => _buildWeekDay(day)),
            ]),
      ),
    ]);
  }

  Widget _buildWeekDay(WeeklyDayModel day) {
    final shortDay = day.day.substring(0, 3).toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        SizedBox(
          width: 36,
          child: Text(shortDay,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: day.classes.isEmpty
              ? const Text('No classes',
                  style: TextStyle(color: Colors.grey, fontSize: 13))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: day.classes
                      .map((c) => Text(
                            '${_formatTime(c.startTime)} - ${c.title}',
                            style: const TextStyle(fontSize: 13),
                          ))
                      .toList(),
                ),
        ),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildEmpty(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        const Icon(Icons.calendar_today_outlined,
            size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        Text(subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ]),
    );
  }

  Future<bool?> _showConfirm(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          Column(children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(title,
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ],
      ),
    );
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final min = parts[1];
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    return '${h.toString().padLeft(2, '0')}:$min $period';
  }

  String _capitalizeDay(String? day) {
    if (day == null || day.isEmpty) return '';
    return day[0].toUpperCase() + day.substring(1);
  }
}