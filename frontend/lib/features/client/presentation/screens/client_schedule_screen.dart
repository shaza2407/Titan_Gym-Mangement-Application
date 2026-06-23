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

  // ── Past-class check ──────────────────────────────────────────────────────
  bool _isPast(ClassModel c) {
    if (c.nextDate == null) return false;
    final classDate = DateTime.tryParse(c.nextDate!);
    if (classDate == null) return false;
    final parts = c.startTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final min = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final localClassDate = classDate.toLocal();
    final classDateTime = DateTime(
      localClassDate.year,
      localClassDate.month,
      localClassDate.day,
      hour,
      min,
    );
    return classDateTime.isBefore(DateTime.now());
  }

  bool _isBrowsePast(ClassModel c) {
    if (c.nextDate == null) return false;
    final classDate = DateTime.tryParse(c.nextDate!);
    if (classDate == null) return false;
    final parts = c.startTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final min = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final localClassDate = classDate.toLocal();
    final classDateTime = DateTime(
      localClassDate.year,
      localClassDate.month,
      localClassDate.day,
      hour,
      min,
    );
    return classDateTime.isBefore(DateTime.now());
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
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              ),
            );
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF3F4F6),
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
                    'Timetable',
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
                  _buildStats(ctrl),
                  const SizedBox(height: 16),
                  _buildTabs(ctrl),
                  const SizedBox(height: 16),
                  if (ctrl.selectedTab == 0) _buildMyClasses(ctrl),
                  if (ctrl.selectedTab == 1) _buildBrowse(ctrl),
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
      child: SizedBox(
        height: 140,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
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
          _buildTab(ctrl, 0, 'My Classes This Week'),
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
              color: selected
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  // ── My Classes — grouped by day, image-style layout ───────────────────────
  // ── My Classes — full week Mon→Sun ────────────────────────────────────────
  Widget _buildMyClasses(ClientScheduleController ctrl) {
    if (ctrl.weekly.isEmpty) {
      return _buildEmpty(
        'No schedule available',
        'Pull to refresh or check back later',
      );
    }

    return Column(
      children: ctrl.weekly.map((day) => _buildWeekDayCard(ctrl, day)).toList(),
    );
  }

  Widget _buildWeekDayCard(ClientScheduleController ctrl, WeeklyDayModel day) {
    final hasClasses = day.classes.isNotEmpty;
    final dayLabel = day.day[0].toUpperCase() + day.day.substring(1);
    final count = day.classes.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Day header ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: hasClasses
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  dayLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasClasses ? Colors.black : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: hasClasses
                        ? const Color(0xFFEEEDFE)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasClasses
                        ? '$count ${count == 1 ? 'class' : 'classes'}'
                        : 'No classes',
                    style: TextStyle(
                      color: hasClasses
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF9CA3AF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Class rows (only if any) ────────────────────────────
          if (hasClasses) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            ...day.classes.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;

              // Find the matching ClassModel from myClasses for unenroll + capacity
              final classModel = ctrl.myClasses
                  .where((m) => m.id == item.id)
                  .firstOrNull;

              return Column(
                children: [
                  _buildWeekClassRow(ctrl, item, classModel),
                  if (idx < day.classes.length - 1)
                    const Divider(
                      height: 1,
                      color: Color(0xFFE5E7EB),
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekClassRow(
    ClientScheduleController ctrl,
    WeeklyClassItem item,
    ClassModel? classModel,
  ) {
    final past = classModel != null ? _isPast(classModel) : false;

    final ratio = classModel != null && classModel.maxClients > 0
        ? classModel.currentClients / classModel.maxClients
        : 0.0;
    final capacityColor = classModel == null
        ? const Color(0xFF10B981)
        : classModel.isFull
        ? Colors.red
        : ratio > 0.8
        ? Colors.orange
        : const Color(0xFF10B981);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Time ────────────────────────────────────────────────
          SizedBox(
            width: 72,
            child: Text(
              _formatTime(item.startTime),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: past ? const Color(0xFF9CA3AF) : const Color(0xFF4F46E5),
              ),
            ),
          ),

          // ── Vertical divider ─────────────────────────────────────
          Container(
            width: 1,
            height: 44,
            color: const Color(0xFFE5E7EB),
            margin: const EdgeInsets.only(right: 12),
          ),

          // ── Title + meta ─────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: past ? const Color(0xFF9CA3AF) : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      item.coachName ?? 'Gym Instructor',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${item.duration} min',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Capacity badge ───────────────────────────────────────
          if (classModel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: capacityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: capacityColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                '${classModel.currentClients}/${classModel.maxClients}',
                style: TextStyle(
                  color: capacityColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          const SizedBox(width: 4),

          // ── Three-dot unenroll menu ──────────────────────────────
          if (classModel != null)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: Color(0xFF6B7280),
                size: 20,
              ),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) async {
                if (value == 'unenroll') {
                  if (past) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'This class has already passed and cannot be cancelled.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  final confirm = await _showConfirm(
                    'Unenroll',
                    'Are you sure you want to cancel your enrollment in ${item.title}?',
                  );
                  if (confirm == true) {
                    final success = await ctrl.unenroll(
                      widget.token,
                      classModel.id,
                      classModel.nextDate ?? '',
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unenrolled successfully'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    }
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'unenroll',
                  child: Row(
                    children: [
                      Icon(
                        past ? Icons.block : Icons.close,
                        color: past ? Colors.orange : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Unenroll',
                        style: TextStyle(
                          color: past ? Colors.orange : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            // No classes enrolled for this slot — no menu
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  // ── Browse All ────────────────────────────────────────────────────────────
  Widget _buildBrowse(ClientScheduleController ctrl) {
    // Filter out past classes on the client side
    final filtered = ctrl.browseClasses
        .where((c) => !_isBrowsePast(c))
        .toList();

    return Column(
      children: [
        // Day filter chips
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
                      color: selected
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFFD1D5DB),
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
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
          )
        else if (filtered.isEmpty)
          _buildEmpty(
            'No upcoming classes',
            'All sessions for this day have passed',
          )
        else
          ...filtered.map((c) => _buildBrowseCard(ctrl, c)),
      ],
    );
  }

  Widget _buildBrowseCard(ClientScheduleController ctrl, ClassModel c) {
    final ratio = c.maxClients > 0 ? (c.currentClients / c.maxClients) : 0.0;
    final isFull = c.isFull && !c.isEnrolled;

    final capacityColor = c.isFull
        ? Colors.red
        : ratio > 0.8
        ? Colors.orange
        : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              Expanded(
                child: Row(
                  children: [
                    Text(
                      c.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (c.isEnrolled) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 58, 189, 115),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 13,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Enrolled',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Capacity badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: capacityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people_outline, color: capacityColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${c.currentClients}/${c.maxClients}',
                      style: TextStyle(
                        color: capacityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Day · time · duration ────────────────────────────────
          Row(
            children: [
              Text(
                _capitalizeDay(c.dayOfWeek) ?? '',
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.access_time, size: 13, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                '${_formatTime(c.startTime)} (${c.duration} min)',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // ── Coach ─────────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 6),
              Text(
                'Coach: ${c.coachName ?? 'Gym Instructor'}',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Action button ─────────────────────────────────────────
          isFull
              ? Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Session Full',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
              : c.isEnrolled
              ? SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
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
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Unenrolled successfully'
                                  : ctrl.errorMessage ?? 'Failed',
                            ),
                            backgroundColor: success
                                ? const Color(0xFF10B981)
                                : Colors.red,
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color.fromARGB(255, 255, 126, 117),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Unenroll',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () async {
                      final success = await ctrl.enroll(
                        widget.token,
                        c.id,
                        c.nextDate ?? '',
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Enrolled in ${c.title}!'
                                : ctrl.errorMessage ?? 'Enroll failed',
                          ),
                          backgroundColor: success
                              ? const Color(0xFF10B981)
                              : Colors.red,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 83, 46, 216),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Enroll',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black,
            ),
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
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message, style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Unenroll',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
