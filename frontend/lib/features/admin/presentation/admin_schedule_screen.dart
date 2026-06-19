// lib/features/admin/presentation/screens/admin_schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/admin_schedule_controller.dart';
import '../domain/schedule_model.dart';
import './class_form_screen.dart';

class AdminScheduleScreen extends StatefulWidget {
  final String token;
  final int gymId;
  final VoidCallback? onBack;

  const AdminScheduleScreen({
    super.key,
    required this.token,
    required this.gymId,
    this.onBack, required void Function(int index) onTabChange,
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<AdminScheduleController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  if (widget.onBack != null) widget.onBack!();
                },
              ),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Schedule Management',
                      style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Manage classes and approvals',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
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
                      child: Text(ctrl.errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),
                  if (ctrl.selectedTab == 0) _buildScheduleTab(ctrl),
                  if (ctrl.selectedTab == 1) _buildTableTab(ctrl),
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
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _buildTab(ctrl, 0, 'Schedule'),
          _buildTab(ctrl, 1, 'Table', icon: Icons.grid_view),
          _buildTab(ctrl, 2, 'Requests', badge: ctrl.requests.length),
        ],
      ),
    );
  }

  Widget _buildTab(AdminScheduleController ctrl, int index, String label, {IconData? icon, int badge = 0}) {
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
                Icon(icon, size: 16, color: selected ? Colors.black : Colors.grey),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                    color: selected ? Colors.black : Colors.grey,
                  )),
              if (badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Schedule Tab ──────────────────────────────────────────────────────────
  Widget _buildScheduleTab(AdminScheduleController ctrl) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(Icons.calendar_today, '${ctrl.stats?.totalClasses ?? 0}', 'Total Classes', const Color(0xFF4F46E5)),
            const SizedBox(width: 12),
            _buildStatCard(Icons.people_outline, '${ctrl.stats?.totalEnrolled ?? 0}', 'Enrolled', const Color(0xFF4CAF50)),
            const SizedBox(width: 12),
            _buildStatCard(Icons.access_time, '${ctrl.stats?.totalCoaches ?? 0}', 'Coaches', Colors.orange),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () => _openClassForm(ctrl),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Create New Class', style: TextStyle(color: Colors.white, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (ctrl.classes.isEmpty)
          _buildEmpty('No classes yet', 'Create your first class to get started')
        else
          ...ctrl.classes.map((c) => _buildOverviewCard(ctrl, c)),
        const SizedBox(height: 16),
        _buildWeeklySchedule(ctrl),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(AdminScheduleController ctrl, ClassSessionModel c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(c.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: ctrl.capacityColor(c), borderRadius: BorderRadius.circular(10)),
                child: Text('${c.currentClients}/${c.maxClients}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          Text('Coach ${c.coachName ?? ''}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _buildChip(c.isRecurring ? (_capitalize(c.dayOfWeek) ?? '') : (c.date ?? '')),
              _buildChip(_formatTime(c.startTime)),
              _buildChip('${c.duration} min'),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(ctrl, c),
              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
              label: const Text('Delete Class', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySchedule(AdminScheduleController ctrl) {
    final weekly = ctrl.weeklySchedule;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("This Week's Schedule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('All your classes this week', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          ...weekly.entries.where((e) => e.value.isNotEmpty).map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_capitalize(entry.key) ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...entry.value.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(width: 3, height: 30, color: const Color(0xFF4F46E5)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text(_formatTime(c.startTime), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${c.currentClients}/${c.maxClients}', style: const TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            );
          }),
          if (weekly.values.every((v) => v.isEmpty))
            const Text('No classes this week', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // ── Table Tab ─────────────────────────────────────────────────────────────
  Widget _buildTableTab(AdminScheduleController ctrl) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AdminScheduleController.days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final day = AdminScheduleController.days[i];
              final selected = ctrl.selectedDay == day;
              return GestureDetector(
                onTap: () => ctrl.setDayFilter(day),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? Colors.black : Colors.grey.shade300),
                  ),
                  child: Text(
                    day == 'All' ? 'All Days' : (_capitalize(day) ?? '').substring(0, 3),
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (ctrl.filteredClasses.isEmpty)
          _buildEmpty('No classes', 'Try a different day')
        else
          ...ctrl.filteredClasses.map((c) => _buildTableCard(ctrl, c)),
      ],
    );
  }

  Widget _buildTableCard(AdminScheduleController ctrl, ClassSessionModel c) {
    final color = ctrl.capacityColor(c);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(c.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Icon(Icons.people, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text('${c.currentClients}/${c.maxClients}',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(_capitalize(c.dayOfWeek) ?? (c.date ?? ''),
                  style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 10),
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${_formatTime(c.startTime)} (${c.duration} min)', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('Coach: ${c.coachName ?? ''}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openClassForm(ctrl, existing: c),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Edit Class'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showMembers(ctrl, c),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('View Members'),
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
      return _buildEmpty('No pending requests', 'New coach requests will show up here');
    }
    return Column(children: ctrl.requests.map((r) => _buildRequestCard(ctrl, r)).toList());
  }

  Widget _buildRequestCard(AdminScheduleController ctrl, ClassRequestModel r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(r.className, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                child: const Text('Pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Text('Coach ${r.coachName ?? ''}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _buildChip(r.isRecurring ? (_capitalize(r.dayOfWeek) ?? '') : (r.requestedDate ?? '')),
              _buildChip(_formatTime(r.requestedTime)),
              _buildChip('${r.duration} min'),
              _buildChip('Max: ${r.maxCapacity}'),
            ],
          ),
          if (r.reasonForRequest != null && r.reasonForRequest!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reason:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(r.reasonForRequest!, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text('Requested on ${r.createdAt}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _respondToRequest(ctrl, r, approve: true),
                  icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                  label: const Text('Approve', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _respondToRequest(ctrl, r, approve: false),
                  icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                  label: const Text('Reject', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _openClassForm(AdminScheduleController ctrl, {ClassSessionModel? existing}) async {
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
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing != null ? 'Class updated' : 'Class created'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    }
  }

  Future<void> _confirmDelete(AdminScheduleController ctrl, ClassSessionModel c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Class', textAlign: TextAlign.center),
        content: Text('Are you sure you want to delete "${c.title}"?', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class deleted')));
      }
    }
  }

  Future<void> _respondToRequest(AdminScheduleController ctrl, ClassRequestModel r, {required bool approve}) async {
    final success = approve
        ? await ctrl.approveRequest(widget.token, widget.gymId, r.id)
        : await ctrl.rejectRequest(widget.token, widget.gymId, r.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Request approved' : 'Request rejected')),
      );
    }
  }

  void _showMembers(AdminScheduleController ctrl, ClassSessionModel c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => FutureBuilder(
        future: ctrl.getClassMembers(widget.token, widget.gymId, c.id),
        builder: (context, snapshot) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${c.currentClients}/${c.maxClients} enrolled', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (snapshot.hasError)
                  const Text('Failed to load members', style: TextStyle(color: Colors.red))
                else if ((snapshot.data ?? []).isEmpty)
                  const Text('No members enrolled yet', style: TextStyle(color: Colors.grey))
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final m = snapshot.data![i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFF0F0FF),
                            child: Icon(Icons.person_outline, color: Color(0xFF4F46E5)),
                          ),
                          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildEmpty(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
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

  String? _capitalize(String? s) {
    if (s == null || s.isEmpty) return null;
    return s[0].toUpperCase() + s.substring(1);
  }
}