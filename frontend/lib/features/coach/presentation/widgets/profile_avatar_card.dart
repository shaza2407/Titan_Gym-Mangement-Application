import 'package:flutter/material.dart';
import '../controllers/coach_profile_controller.dart';

class ProfileAvatarCard extends StatelessWidget {
  final CoachProfileController ctrl;

  const ProfileAvatarCard({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final name = ctrl.profile?.name ?? '';
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: const Color.fromARGB(255, 206, 132, 28),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text('Coach', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}