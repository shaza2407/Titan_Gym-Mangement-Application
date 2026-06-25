import 'package:flutter/material.dart';
import '../controllers/coach_schedule_controller.dart';
import '../../domain/coach_schedule_model.dart';
import '../widgets/coach_ui_utils.dart';

class ClassRequestsList extends StatelessWidget {
  final CoachScheduleController ctrl;
  final String token;

  const ClassRequestsList({super.key, required this.ctrl, required this.token});

  @override
  Widget build(BuildContext context) {
    if (ctrl.requests.isEmpty) {
      return const EmptyState(
        title: 'No requests yet',
        subtitle: 'Use the black button above to request a class time.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ctrl.requests.map((r) => _RequestCard(request: r, ctrl: ctrl, token: token)).toList(),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final CoachClassRequestModel request;
  final CoachScheduleController ctrl;
  final String token;

  const _RequestCard({required this.request, required this.ctrl, required this.token});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (request.status.toLowerCase()) {
      'approved' => CoachColors.success,
      'rejected' => CoachColors.danger,
      _ => CoachColors.warning,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
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
                  request.className,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              if (request.status.toLowerCase() == 'pending')
                GestureDetector(
                  onTap: () async {
                    final confirm = await showConfirmDialog(
                      context,
                      title: 'Cancel Request',
                      content: 'Are you sure you want to delete this class request?',
                      confirmLabel: 'Cancel Request',
                    );
                    if (confirm == true) {
                      final success = await ctrl.deleteRequest(token, request.id);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request cancelled'), backgroundColor: Colors.green),
                        );
                      }
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
              Text(
                request.isRecurring ? capitalizeDay(request.dayOfWeek) : request.requestedDate ?? '',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                formatTime(request.requestedTime),
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Submitted: ${formatDate(request.createdAt)}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}