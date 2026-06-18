import 'package:flutter/material.dart';
import 'package:frontend/features/admin/presentation/admin_shell.dart';
import 'package:provider/provider.dart';
import '../controller/admin_gym_controller.dart';
import '../data/gym_repository.dart';
import './create_gym_screen.dart';
import '../../shared/logout_button.dart';

class AdminDashboardScreen extends StatelessWidget {
  final String token;
  const AdminDashboardScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminGymController()..loadGyms(token: token),
      child: Consumer<AdminGymController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFEEF0F8),
            body: Column(
              children: [
                // ── Purple Header ─────────────────────────────────
                _buildHeader(context, controller, token),

                // ── Body ──────────────────────────────────────────
                Expanded(
                  child: controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : controller.errorMessage != null
                          ? Center(
                              child: Text(controller.errorMessage!,
                                  style: const TextStyle(color: Colors.red)))
                          : ListView(
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
                                          child: CreateGymScreen(token: token),
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add,
                                        color: Colors.white),
                                    label: const Text('Create New Gym',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4F46E5),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
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
                                          style:
                                              TextStyle(color: Colors.grey)),
                                    ),
                                  )
                                else
                                  ...controller.gyms.map(
                                    (gym) => _buildGymCard(
                                        context, controller, gym),
                                  ),
                              ],
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
      BuildContext context, AdminGymController controller, String token) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF4F46E5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Welcome back,\nAdmin User',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
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

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _statCard(
                    'Total Gyms', '${controller.gyms.length}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                    'Total Members', '${controller.totalMembers}'),
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
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.white, fontSize: 15 , fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

 Widget _buildGymCard(
    BuildContext context, AdminGymController controller, GymModel gym) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border(
        left: BorderSide(color: const Color(0xFF4F46E5), width: 4),
      ),
    ),
    child: InkWell(  // ✅ wrap here
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => AdminGymController(),
            child: AdminShell(gym: gym, token: token),
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
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey), 
              ],
            ),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  gym.location,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                  '—',
                ),
                const SizedBox(width: 24),
                _gymStatChip(
                  Icons.trending_up,
                  const Color(0xFF1D9E75),
                  'Monthly Subscription',
                  '\$${gym.subscriptionPrice.toStringAsFixed(0)}',
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
  Widget _gymStatChip(
      IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}