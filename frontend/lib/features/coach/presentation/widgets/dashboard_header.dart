import 'package:flutter/material.dart';
import '../../../shared/logout_button.dart';
import '../../../notification/token_helper.dart';
import '../../../notification/presentation/notifications_screen.dart';
import '../../../shared/notifications/notification_badge_controller.dart';


class DashboardHeader extends StatelessWidget {
  final String token;
  final NotificationBadgeController badgeCtrl;

  const DashboardHeader({
    super.key,
    required this.token,
    required this.badgeCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color.fromARGB(255, 206, 132, 28),
              child: Icon(Icons.fitness_center, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coach Dashboard',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Welcome back, Coach!',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            AnimatedBuilder(
              animation: badgeCtrl,
              builder: (context, _) {
                return IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined),
                      if (badgeCtrl.hasUnread)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsScreen(
                          userId: getUserIdFromToken(token),
                          token: token,
                        ),
                      ),
                    );
                    if (!context.mounted) return;
                    badgeCtrl.load(token, getUserIdFromToken(token));
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              onPressed: () => showLogoutDialog(context),
            ),
          ],
        ),
      ],
    );
  }
}
