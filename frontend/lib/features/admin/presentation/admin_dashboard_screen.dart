import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/admin_gym_controller.dart';
import '../data/gym_repository.dart';
import './create_gym_screen.dart';
import 'gym_dashboard_screen.dart';     
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
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, controller, token),
                  _buildStats(controller),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: controller,
                              child: CreateGymScreen(token: token),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Create New Gym',
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: controller.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : controller.errorMessage != null
                            ? Center(
                                child: Text(controller.errorMessage!,
                                    style: const TextStyle(color: Colors.red)))
                            : controller.gyms.isEmpty
                                ? const Center(child: Text('No gyms yet. Create one!'))
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: controller.gyms.length,
                                    itemBuilder: (context, index) {
                                      return _buildGymCard(
                                        context,
                                        controller,
                                        controller.gyms[index],
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AdminGymController controller, String token) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF4F46E5),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Welcome back,\nAdmin User',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white), onPressed: () {}),
                  IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () => showLogoutDialog(context)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Select a gym to manage', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildStats(AdminGymController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _statCard('Total Gyms', '${controller.gyms.length}')),
          const SizedBox(width: 12),
          Expanded(child: _statCard('Total Members', '${controller.totalMembers}')),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGymCard(
      BuildContext context, AdminGymController controller, GymModel gym) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(gym.gymName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  // ← tapping arrow navigates to the gym dashboard
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: controller,
                          child: GymDashboardScreen(gym: gym, token: token),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(gym.location,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${gym.openingHours} - ${gym.closingHours}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.fitness_center, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(gym.gymType,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const Spacer(),
              Text('\$${gym.subscriptionPrice.toStringAsFixed(0)}/mo',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

