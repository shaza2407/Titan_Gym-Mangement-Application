//done
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/admin_schedule_controller.dart';
import '../../domain/schedule_model.dart';
import 'class_form_screen.dart';

class AdminScheduleScreen extends StatefulWidget {
  final String token;
  final int gymId;
  final VoidCallback? onBack;
  final void Function(int index) onTabChange;

  const AdminScheduleScreen({
    super.key,
    required this.token,
    required this.gymId,
    this.onBack,
    required this.onTabChange,
  });

  @override
  State<AdminScheduleScreen> createState() => _AdminScheduleScreenState();
}

class _AdminScheduleScreenState extends State<AdminScheduleScreen> {
  late AdminScheduleController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AdminScheduleController();
    _ctrl.loadAll(widget.token, widget.gymId);
  }
  
  void _goToDashboard() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      widget.onTabChange(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<AdminScheduleController>(
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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _goToDashboard,
              ),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule Management',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Manage classes and approvals',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TextButton.icon(
                    onPressed: () => _openClassForm(ctrl),
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text(
                      'New Class',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTabs(ctrl),
                  const SizedBox(height: 16),
                  if (ctrl.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        ctrl.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (ctrl.selectedTab == 0) _buildScheduleTab(ctrl),
                  if (ctrl.selectedTab == 1) _buildAllClassesTab(ctrl),
                  if (ctrl.selectedTab == 2) _buildRequestsTab(ctrl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────
  Widget _buildTabs(AdminScheduleController ctrl) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab(ctrl, 0, 'Schedule'),
          _buildTab(ctrl, 1, 'All Classes', icon: Icons.grid_view),
          _buildTab(ctrl, 2, 'Requests', badge: ctrl.requests.length),
        ],
      ),
    );
  }

  Widget _buildTab(
    AdminScheduleController ctrl,
    int index,
    String label, {
    IconData? icon,
    int badge = 0,
  }) {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.black : Colors.grey,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                  color: selected ? Colors.black : Colors.grey,
                ),
              ),
              if (badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Schedule Tab (weekly view only) ───────────────────────────────────────
  Widget _buildScheduleTab(AdminScheduleController ctrl) {
    final weekly = ctrl.weeklySchedule;

    return Column(
      children: [
        const SizedBox(height: 16),
        // ── Weekly schedule ──
        ...weekly.entries.map(
          (entry) => _buildDaySection(ctrl, entry.key, entry.value),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySection(
    AdminScheduleController ctrl,
    String day,
    List<ClassSessionModel> dayClasses,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _capitalize(day) ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: dayClasses.isEmpty
                      ? Colors.grey.shade100
                      : const Color(0xFFF0F0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dayClasses.isEmpty
                      ? 'No classes'
                      : '${dayClasses.length} class${dayClasses.length == 1 ? '' : 'es'}',
                  style: TextStyle(
                    color: dayClasses.isEmpty
                        ? Colors.grey
                        : const Color(0xFF4F46E5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (dayClasses.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            ...dayClasses.map((c) => _buildScheduleClassRow(ctrl, c)),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleClassRow(
    AdminScheduleController ctrl,
    ClassSessionModel c,
  ) {
    final capacityColor = ctrl.capacityColor(c);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Time column
          SizedBox(
            width: 64,
            child: Text(
              _formatTime(c.startTime),
              style: const TextStyle(
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Divider bar
          Container(width: 2, height: 40, color: const Color(0xFFF0F0F0)),
          const SizedBox(width: 12),
          // Class info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      c.coachName ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${c.duration} min',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Capacity badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: capacityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: capacityColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${c.currentClients}/${c.maxClients}',
              style: TextStyle(
                color: capacityColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Three-dot dropdown menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'view') _showMembers(ctrl, c);
              if (value == 'edit') _openClassForm(ctrl, existing: c);
              if (value == 'delete') _confirmDelete(ctrl, c);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 18,
                      color: Color(0xFF4F46E5),
                    ),
                    SizedBox(width: 10),
                    Text('View Members'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: Colors.black87),
                    SizedBox(width: 10),
                    Text('Edit Class'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Delete Class', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── All Classes Tab ───────────────────────────────────────────────────────
  Widget _buildAllClassesTab(AdminScheduleController ctrl) {
    final classes = ctrl.filteredClasses;
    final s = ctrl.stats;
    return Column(
      children: [
        // ── Stats row ──
        Row(
          children: [
            _buildStatCard(
              Icons.calendar_today,
              '${s?.totalClasses ?? 0}',
              'Total Classes',
              const Color(0xFF4F46E5),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              Icons.people,
              '${s?.totalEnrolled ?? 0}',
              'Enrolled',
              const Color(0xFF22A45D),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              Icons.access_time,
              '${s?.totalCoaches ?? 0}',
              'Coaches',
              const Color(0xFFF59E0B),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ── Create New Class button ──
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openClassForm(ctrl),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Create New Class',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // ── Day filter chips ──
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AdminScheduleController.days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final day = AdminScheduleController.days[i];
              final selected = ctrl.selectedDay == day;
              return GestureDetector(
                onTap: () => ctrl.setDayFilter(day),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? Colors.black : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    day == 'All'
                        ? 'All Days'
                        : (_capitalize(day) ?? '').substring(0, 3),
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // ── Class cards ──
        if (classes.isEmpty)
          _buildEmpty('No classes', 'Try a different day')
        else
          ...classes.map((c) => _buildAllClassesCard(ctrl, c)),
      ],
    );
  }

  Widget _buildAllClassesCard(
    AdminScheduleController ctrl,
    ClassSessionModel c,
  ) {
    final color = ctrl.capacityColor(c);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '${c.currentClients}/${c.maxClients}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                c.isRecurring
                    ? (_capitalize(c.dayOfWeek) ?? '')
                    : (c.date ?? ''),
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${_formatTime(c.startTime)} (${c.duration} min)',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Coach: ${c.coachName ?? ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openClassForm(ctrl, existing: c),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showMembers(ctrl, c),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Members'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _confirmDelete(ctrl, c),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Requests Tab ──────────────────────────────────────────────────────────
  Widget _buildRequestsTab(AdminScheduleController ctrl) {
    if (ctrl.requests.isEmpty) {
      return _buildEmpty(
        'No pending requests',
        'New coach requests will show up here',
      );
    }
    return Column(
      children: ctrl.requests.map((r) => _buildRequestCard(ctrl, r)).toList(),
    );
  }

  Widget _buildRequestCard(AdminScheduleController ctrl, ClassRequestModel r) {
    final isRecurring = r.isRecurring;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: avatar + name + badge ──
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEEEDFE),
                child: Text(
                  (r.coachName ?? '?')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF3C3489),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.className,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      r.coachName ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF854F0B),
                  ),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),

          // ── Chips ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                Icons.calendar_today_outlined,
                isRecurring
                    ? (_capitalize(r.dayOfWeek) ?? '')
                    : (r.requestedDate ?? ''),
              ),
              _buildInfoChip(Icons.access_time, _formatTime(r.requestedTime)),
              _buildInfoChip(Icons.timer_outlined, '${r.duration} min'),
              _buildInfoChip(Icons.people_outline, 'Max ${r.maxCapacity}'),
              _buildTagChip(
                isRecurring ? Icons.repeat : Icons.looks_one_outlined,
                isRecurring ? 'Recurring' : 'One-time',
                isRecurring ? const Color(0xFFEEEDFE) : const Color(0xFFE1F5EE),
                isRecurring ? const Color(0xFF3C3489) : const Color(0xFF0F6E56),
              ),
            ],
          ),

          // ── Reason box ──
          if (r.reasonForRequest != null && r.reasonForRequest!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 15,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.reasonForRequest!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          Text(
            'Requested on ${r.createdAt}',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 12),

          // ── Actions ──
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _respondToRequest(ctrl, r, approve: true),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Approve',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _respondToRequest(ctrl, r, approve: false),
                  icon: const Icon(
                    Icons.cancel_outlined,
                    size: 18,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Replace _buildChip with these two helpers:
  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: fg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _openClassForm(
    AdminScheduleController ctrl, {
    ClassSessionModel? existing,
  }) async {
    ctrl.clearError();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClassFormScreen(
          token: widget.token,
          gymId: widget.gymId,
          controller: ctrl,
          existing: existing,
        ),
      ),
    );
    ctrl.clearError();
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing != null ? 'Class updated' : 'Class created'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    AdminScheduleController ctrl,
    ClassSessionModel c,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Class', textAlign: TextAlign.center),
        content: Text(
          'Are you sure you want to delete "${c.title}"?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await ctrl.deleteClass(widget.token, widget.gymId, c.id);
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Class deleted')));
      }
    }
  }

  Future<void> _respondToRequest(
    AdminScheduleController ctrl,
    ClassRequestModel r, {
    required bool approve,
  }) async {
    final success = approve
        ? await ctrl.approveRequest(widget.token, widget.gymId, r.id)
        : await ctrl.rejectRequest(widget.token, widget.gymId, r.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Request approved' : 'Request rejected'),
        ),
      );
    }
  }

  void _showMembers(AdminScheduleController ctrl, ClassSessionModel c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FutureBuilder(
        future: ctrl.getClassMembers(widget.token, widget.gymId, c.id),
        builder: (context, snapshot) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${c.currentClients}/${c.maxClients} enrolled',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (snapshot.hasError)
                  const Text(
                    'Failed to load members',
                    style: TextStyle(color: Colors.red),
                  )
                else if ((snapshot.data ?? []).isEmpty)
                  const Text(
                    'No members enrolled yet',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final m = snapshot.data![i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFF0F0FF),
                            child: Icon(
                              Icons.person_outline,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                          title: Text(
                            m.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(m.email),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
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
      ),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
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

  String? _capitalize(String? s) {
    if (s == null || s.isEmpty) return null;
    return s[0].toUpperCase() + s.substring(1);
  }
}
