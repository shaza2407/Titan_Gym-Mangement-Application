import 'package:flutter/material.dart';
import '../../presentation/controllers/coach_gyms_controller.dart';
import '../screens/gym_schedule_screen.dart';
import '../screens/gym_announcements_screen.dart';
import 'gym_card_widget.dart';
import 'coach_ui_utils.dart';


class GymsListView extends StatelessWidget {
  final CoachGymsController ctrl;
  final String token;
  final VoidCallback onDataChanged;

  const GymsListView({super.key, required this.ctrl, required this.token, required this.onDataChanged,});

  @override
  Widget build(BuildContext context) {
    if (ctrl.myGyms.isEmpty) {
      return const EmptyState(
        title: 'No active gyms yet',
        subtitle: 'Once you join a gym, it will show up here.',
        icon: Icons.business,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ctrl.myGyms.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final gym = ctrl.myGyms[index];
        return GymCardWidget(
          gym: gym,
          onSchedule: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GymScheduleScreen(token: token, gymId: gym.gymId, gymName: gym.gymName),
              ),
            );
          },
          onAnnouncements: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GymAnnouncementsScreen(token: token, gymId: gym.gymId, gymName: gym.gymName),
              ),
            );
          },
        );
      },
    );
  }
}