// lib/features/client/presentation/screens/client_achievement_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/client_achievement_controller.dart';
import '../../domain/achievement_model.dart';

class ClientAchievementScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onBack;
  const ClientAchievementScreen({super.key, required this.token, this.onBack});

  @override
  State<ClientAchievementScreen> createState() =>
      _ClientAchievementScreenState();
}

class _ClientAchievementScreenState extends State<ClientAchievementScreen> {
  late ClientAchievementController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ClientAchievementController();
    _ctrl.addListener(_onError);
    _ctrl.loadAchievements(widget.token);
  }

  void _onError() {
    if (_ctrl.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ctrl.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      _ctrl.clearError();
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onError);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: widget.onBack != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: widget.onBack,
                  )
                : const BackButton(color: Colors.black),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Badges',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Track your fitness milestones',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                ),
              ],
            ),
            bottom: const TabBar(
              labelColor: Color(0xFF4F46E5),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF4F46E5),
              tabs: [
                Tab(text: 'All'),
                Tab(text: 'Earned'),
                Tab(text: 'Locked'),
              ],
            ),
          ),
          body: Consumer<ClientAchievementController>(
            builder: (context, ctrl, _) {
              if (ctrl.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                );
              }

              if (ctrl.errorMessage != null) {
                return Center(
                  child: Text(
                    ctrl.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (ctrl.achievements.isEmpty) {
                return const Center(
                  child: Text(
                    'No achievements available.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                );
              }

              final unlocked = ctrl.achievements
                  .where((a) => a.isUnlocked)
                  .toList();
              final locked = ctrl.achievements
                  .where((a) => !a.isUnlocked)
                  .toList();

              return TabBarView(
                children: [
                  _buildList(ctrl.achievements),
                  _buildList(unlocked),
                  _buildList(locked),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<AchievementModel> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'No achievements found here.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(list[index]);
      },
    );
  }

  Widget _buildAchievementCard(AchievementModel ach) {
    final bool isUnlocked = ach.isUnlocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB),
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFFEEF2FF)
                  : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: ColorFiltered(
                colorFilter: isUnlocked
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                    : const ColorFilter.matrix(<double>[
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                child: Opacity(
                  opacity: isUnlocked ? 1.0 : 0.4,
                  child: Text(ach.icon, style: const TextStyle(fontSize: 32)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ach.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked
                              ? Colors.black
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    if (isUnlocked)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4F46E5),
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ach.description,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${ach.currentValue} / ${ach.target} ${ach.unit}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${ach.progressPercentage}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ach.progressPercentage / 100,
                    backgroundColor: const Color(0xFFE5E7EB),
                    color: isUnlocked
                        ? const Color(0xFF10B981)
                        : const Color(0xFF4F46E5),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
