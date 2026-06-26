//done
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/admin_gym_controller.dart';
import '../controller/gym_stats_controller.dart';
import './create_gym_screen.dart';
import '../../../shared/logout_button.dart';
import 'package:frontend/features/notification/presentation/notifications_screen.dart';
import 'package:frontend/features/notification/token_helper.dart';
import 'package:frontend/main.dart';
import 'package:frontend/features/admin/presentation/widgets/admin_bottom_navbar.dart';
import 'package:frontend/features/admin/domain/gym_model.dart';
import 'package:frontend/features/shared/notifications/notification_badge_controller.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String token;
  const AdminDashboardScreen({super.key, required this.token});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with RouteAware {
  late AdminGymController _controller;
  late NotificationBadgeController _badgeCtrl;

  @override
  void initState() {
    super.initState();
    _controller = AdminGymController();
    _badgeCtrl = NotificationBadgeController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadGyms(token: widget.token);
      _badgeCtrl.load(widget.token, getUserIdFromToken(widget.token));
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _controller.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _controller.loadGyms(token: widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _controller),
        ChangeNotifierProvider.value(value: _controller.statsController),
      ],
      child: Consumer2<AdminGymController, GymStatsController>(
        builder: (context, controller, stats, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFEEF0F8),
            body: Column(
              children: [
                _buildHeader(context, controller, stats),
                Expanded(
                  child: controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : controller.errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                controller.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    controller.loadGyms(token: widget.token),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              controller.loadGyms(token: widget.token),
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Create New Gym Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ChangeNotifierProvider.value(
                                            value: controller,
                                            child: CreateGymScreen(
                                              token: widget.token,
                                            ),
                                          ),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Create New Gym',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Gym Cards
                              if (controller.gyms.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Text(
                                      'No gyms yet. Create your first one!',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                ...controller.gyms.map(
                                  (gym) => _buildGymCard(
                                    context,
                                    controller,
                                    stats,
                                    gym,
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AdminGymController controller,
    GymStatsController stats,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      decoration: const BoxDecoration(color: Color(0xFF4F46E5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Welcome back,\nAdmin User',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _badgeCtrl,
                    builder: (context, _) {
                      return IconButton(
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                            ),
                            if (_badgeCtrl.hasUnread)
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
                                userId: getUserIdFromToken(widget.token),
                                token: widget.token,
                              ),
                            ),
                          );
                          if (mounted) {
                            _badgeCtrl.load(
                              widget.token,
                              getUserIdFromToken(widget.token),
                            );
                          }
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () => showLogoutDialog(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select a gym to manage',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statCard('Total Gyms', '${controller.gyms.length}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: stats.isLoadingTotalMembers
                    ? _statCard('Total Members', '...')
                    : _statCard('Total Members', '${stats.totalMembers}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGymCard(
    BuildContext context,
    AdminGymController controller,
    GymStatsController stats,
    GymModel gym,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: const Color(0xFF4F46E5), width: 4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => AdminGymController(),
              child: AdminShell(gym: gym, token: widget.token),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      gym.gymName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    gym.location,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                gym.gymType,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _gymStatChip(
                    Icons.people_outline,
                    const Color(0xFF4F46E5),
                    'Members',
                    '${stats.memberCount(gym.gymID)}',
                  ),
                  const SizedBox(width: 24),
                  _gymStatChip(
                    Icons.sports_gymnastics_sharp,
                    const Color(0xFF1D9E75),
                    'Coaches',
                    '${stats.coachCount(gym.gymID)}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gymStatChip(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}
