import 'package:flutter/material.dart';
import '../../presentation/controllers/coach_gyms_controller.dart';
import 'coach_ui_utils.dart'; 
import 'announcement_card.dart';

class AnnouncementsListView extends StatelessWidget {
  final CoachGymsController ctrl;

  const AnnouncementsListView({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.announcements.isEmpty) {
      return const EmptyState(
        title: 'No announcements',
        subtitle: 'Announcements from your gyms will show up here.',
        icon: Icons.notifications_none,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ctrl.announcements.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) => AnnouncementCard(announcement: ctrl.announcements[index]),
    );
  }
}