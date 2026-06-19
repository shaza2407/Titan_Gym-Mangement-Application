import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/coach_schedule_controller.dart';
import '../../domain/coach_schedule_model.dart';
import '../../../coach/presentation/screens/coach_ui_utils.dart';
import 'request_class_screen.dart';

class CoachScheduleScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onBack;
  const CoachScheduleScreen({super.key, required this.token, this.onBack});

  @override
  State<CoachScheduleScreen> createState() => _CoachScheduleScreenState();
}

class _CoachScheduleScreenState extends State<CoachScheduleScreen> {
  late final CoachScheduleController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = CoachScheduleController();
    _ctrl.loadAll(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<CoachScheduleController>(
        builder: (context, ctrl, _) {
          return Scaffold(
            backgroundColor: CoachColors.background,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: widget.onBack,
                    )
                  : null,
              title: const Text('Schedule & Requests', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            // Full-screen spinner only on first load; refreshes (pull-to-
            // refresh, post-delete reloads) keep the AppBar and existing
            // content visible instead of flashing a blank screen.
            body: ctrl.isLoading && ctrl.stats == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => ctrl.loadAll(widget.token),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStats(ctrl),
                          const SizedBox(height: 24),
                          _buildRequestButton(ctrl),
                          const SizedBox(height: 24),
                          _buildTabs(ctrl),
                          const SizedBox(height: 20),
                          if (ctrl.selectedTab == 0) ...[
                            _buildHorizontalClassesSection(ctrl),
                            const SizedBox(height: 28),
                            _buildWeekly(ctrl),
                          ],
                          if (ctrl.selectedTab == 1) _buildRequests(ctrl),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildRequestButton(CoachScheduleController ctrl) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestClassScreen(token: widget.token, controller: ctrl),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Request New Class Time',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black, // Your normal color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }


  Widget _buildStats(CoachScheduleController ctrl) {
    return Row(
      children: [
        StatCard(icon: Icons.calendar_today_outlined, value: '${ctrl.stats?.weeklyClasses ?? 0}', label: 'Weekly\nClasses', color: CoachColors.primary),
        const SizedBox(width: 12),
        StatCard(icon: Icons.people_outline, value: '${ctrl.stats?.totalStudents ?? 0}', label: 'Total\nStudents', color: CoachColors.success),
        const SizedBox(width: 12),
        StatCard(icon: Icons.access_time_outlined, value: '${ctrl.stats?.pendingRequests ?? 0}', label: 'Pending\nRequests', color: CoachColors.warning),
      ],
    );
  }

  Widget _buildTabs(CoachScheduleController ctrl) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CoachColors.cardBorder, width: 2))),
      child: Row(
        children: [
          _buildTab(ctrl, 0, 'Overview'),
          _buildTab(ctrl, 1, 'My Requests', badge: ctrl.stats?.pendingRequests),
        ],
      ),
    );
  }

  Widget _buildTab(CoachScheduleController ctrl, int index, String label, {int? badge}) {
    final selected = ctrl.selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => ctrl.setTab(index),
        child: Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: selected ? Colors.black : Colors.transparent, width: 2))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.w600, fontSize: 15, color: selected ? Colors.black : Colors.grey.shade500)),
              if (badge != null && badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: CoachColors.warning, borderRadius: BorderRadius.circular(10)),
                  child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalClassesSection(CoachScheduleController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upcoming Active Classes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 16),
        if (ctrl.myClasses.isEmpty)
          const EmptyState(title: 'No classes', subtitle: 'You have no assigned classes.')
        else
          SizedBox(
            height: 150,
            child: Stack(
              children: [
                ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ctrl.myClasses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) => _buildCompactClassCard(ctrl.myClasses[index], ctrl),
                ),
                // Subtle fade hints there's more to scroll to on the right.
                if (ctrl.myClasses.length > 1)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [CoachColors.background.withOpacity(0), CoachColors.background],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

Widget _buildCompactClassCard(CoachClassModel c, CoachScheduleController ctrl) {
  final isFull = c.currentClients >= c.maxClients;
  final capacityColor = isFull ? CoachColors.danger : CoachColors.success;

  return Container(
    width: 300,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey.shade200),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min, // ← shrink to content
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                c.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            GestureDetector(
              onTap: () async {
                final confirm = await showConfirmDialog(context,
                    title: 'Delete Class',
                    content: 'Remove this class from the schedule?');
                if (confirm == true) {
                  final success = await ctrl.deleteClass(widget.token, c.id);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Class deleted'),
                          backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), // ← was missing child
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: capacityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: capacityColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${c.currentClients}/${c.maxClients}',
                    style: TextStyle(color: capacityColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              c.isRecurring ? capitalizeDay(c.dayOfWeek) : c.date ?? '',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(width: 12),
            Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              formatTime(c.startTime),
              style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12), // ← replaces Spacer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                c.gymName ?? '',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: capacityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${c.currentClients} / ${c.maxClients}',
                style: TextStyle(
                    color: capacityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildWeekly(CoachScheduleController ctrl) {
    if (ctrl.weekly.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('This Week\'s Agenda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ctrl.weekly.map(_buildWeekDay).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDay(CoachWeeklyDayModel day) {
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
                border: Border.all(
                    color: CoachColors.primary.withOpacity(0.3), width: 3),
              ),
            ),
            Text(
              capitalizeDay(day.day),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (day.classes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              'No classes scheduled',
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                  fontStyle: FontStyle.italic),
            ),
          )
        else
          ...day.classes.map(
            (c) => Padding(
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
                        Text(c.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${c.currentClients}/${c.maxClients} booked',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 14, color: CoachColors.primary),
                        const SizedBox(width: 4),
                        Text(formatTime(c.startTime),
                            style: const TextStyle(
                                color: CoachColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        if (c.gymName != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(c.gymName!,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

  Widget _buildRequests(CoachScheduleController ctrl) {
    if (ctrl.requests.isEmpty) {
      return const EmptyState(title: 'No requests yet', subtitle: 'Use the black button above to request a class time.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ctrl.requests.map((r) => _buildRequestCard(r, ctrl)).toList(),
    );
  }

  Widget _buildRequestCard(CoachClassRequestModel r, CoachScheduleController ctrl) {
    final statusColor = switch (r.status.toLowerCase()) {
      'approved' => CoachColors.success,
      'rejected' => CoachColors.danger,
      _ => CoachColors.warning,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(r.className, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black))),
              GestureDetector(
                onTap: () async {
                  final confirm = await showConfirmDialog(context, title: 'Cancel Request', content: 'Are you sure you want to delete this class request?', confirmLabel: 'Cancel Request');
                  if (confirm == true) {
                    final success = await ctrl.deleteRequest(widget.token, r.id);
                    if (success && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request cancelled'), backgroundColor: Colors.green));
                  }
                },
                child: const Icon(Icons.close_rounded, color: Colors.grey, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(r.isRecurring ? capitalizeDay(r.dayOfWeek) : r.requestedDate ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              const SizedBox(width: 16),
              Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(formatTime(r.requestedTime), style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Submitted: ${formatDate(r.createdAt)}', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(r.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}