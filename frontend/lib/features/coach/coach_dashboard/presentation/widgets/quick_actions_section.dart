import 'package:flutter/material.dart';
import 'package:frontend/features/coach/coach_schedule/presentation/screens/coach_schedule_screen.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Section Title
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),

        // 2. Section Subtitle
        Text(
          "Manage your coaching activities",
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16), // Space before the cards start
        // 3. The Action Cards
        Column(
          children: [
            QuickActionCard(
              icon: Icons.calendar_today_outlined,
              title: "My Schedule & Classes",
              subtitle: "View schedule and manage class requests",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CoachScheduleScreen(
                      coachId: 2,
                    ), // Pass the actual coach ID here
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            QuickActionCard(
              icon: Icons.domain, // or apartment_outlined
              title: "My Gyms",
              subtitle: "View gyms you're coaching at",
              onTap: () {},
            ),
            const SizedBox(height: 12),
            QuickActionCard(
              icon: Icons.person_outline,
              title: "My Profile",
              subtitle: "Update your coach information",
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// The Reusable Card Widget
// -----------------------------------------------------------------------------

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // We wrap it in an InkWell so it has that nice ripple effect when tapped!
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12), // Keep ripple inside borders
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          // No shadow on these in the design, just a clean flat border!
        ),
        child: Row(
          children: [
            // The purple icon
            Icon(icon, color: Colors.purple, size: 24),
            const SizedBox(width: 16),

            // The Text Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
