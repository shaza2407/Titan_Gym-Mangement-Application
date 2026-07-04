import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/coach_management_controller.dart';
import '../../domain/gym_model.dart';
import '../../domain/coach_model.dart';
import 'invite_member_screen.dart';
import 'coach_detail_screen.dart';

class CoachManagementScreen extends StatefulWidget {
  final GymModel gym;
  final String token;

  const CoachManagementScreen({
    super.key,
    required this.gym,
    required this.token,
  });

  @override
  State<CoachManagementScreen> createState() => _CoachManagementScreenState();
}

class _CoachManagementScreenState extends State<CoachManagementScreen> {
  late final CoachManagementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CoachManagementController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadCoaches(
        gymId: widget.gym.gymID,
        token: widget.token,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _suspend(int coachId) async {
    final success = await _controller.suspendCoach(
      gymId:   widget.gym.gymID,
      coachId: coachId,
      token:   widget.token,
    );
    if (!mounted) return;
    if (success) {
      await _controller.loadCoaches(
          gymId: widget.gym.gymID, token: widget.token);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coach suspended successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_controller.errorMessage ?? 'Failed to suspend')),
      );
    }
  }

  Future<void> _unsuspend(int coachId) async {
    final errorMsg = await _controller.unsuspendCoach(
      gymId:   widget.gym.gymID,
      coachId: coachId,
      token:   widget.token,
    );
    if (!mounted) return;
    if (errorMsg == null) {
      await _controller.loadCoaches(
          gymId: widget.gym.gymID, token: widget.token);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coach unsuspended successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<CoachManagementController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: _buildAppBar(controller),
            body: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.errorMessage != null && controller.data == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              controller.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => controller.loadCoaches(
                                gymId: widget.gym.gymID,
                                token: widget.token,
                              ),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9C27B0),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => controller.loadCoaches(
                          gymId: widget.gym.gymID,
                          token: widget.token,
                        ),
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildStatsRow(controller),
                            const SizedBox(height: 16),
                            _buildSearchField(controller),
                            const SizedBox(height: 12),
                            _FilterRow(
                              selected: controller.selectedFilter,
                              onSelect: controller.setFilter,
                            ),
                            const SizedBox(height: 16),
                            if (controller.filtered.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text('No coaches found',
                                      style: TextStyle(color: Colors.grey)),
                                ),
                              )
                            else
                              ...controller.filtered.map(
                                (c) => _CoachCard(
                                  coach:       c,
                                  onSuspend:   () => _suspend(c.id),
                                  onUnsuspend: () => _unsuspend(c.id),
                                  onViewDetails: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CoachDetailScreen(coach: c),
                                    ),
                                  ),
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

  PreferredSizeWidget _buildAppBar(CoachManagementController controller) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Coach Management',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text('View and manage gym coaches',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_add,
                color: Colors.white, size: 20),
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InviteMemberScreen(
                  gym:   widget.gym,
                  token: widget.token,
                ),
              ),
            );
            controller.loadCoaches(
              gymId: widget.gym.gymID,
              token: widget.token,
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsRow(CoachManagementController controller) {
    final data = controller.data;
    return Row(
      children: [
        _StatCard(
          label: 'Total Coaches',
          value: '${data?.total ?? 0}',
          icon: Icons.sports_gymnastics,
        ),
        const SizedBox(width: 8),
        _StatCard(
          label: 'Active',
          value: '${data?.active ?? 0}',
          icon: Icons.check_circle_outline,
          color: const Color(0xFF9C27B0),
        ),
        const SizedBox(width: 8),
        _StatCard(
          label: 'Pending',
          value: '${data?.pending ?? 0}',
          icon: Icons.person_add_outlined,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSearchField(CoachManagementController controller) {
    return TextField(
      controller: controller.searchController,
      onChanged: controller.setSearch,
      decoration: InputDecoration(
        hintText: 'Search coaches...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// Filter Row

class _FilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('all', 'All'),
      ('active', 'Active'),
      ('pending', 'Pending'),
      ('suspended', 'Suspended'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: filters.map((f) {
          final isSelected = selected == f.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  f.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:      isSelected ? Colors.white : Colors.grey,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Stat Card

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// Coach Card

class _CoachCard extends StatelessWidget {
  final CoachListItem coach;
  final VoidCallback onSuspend;
  final VoidCallback onUnsuspend;
  final VoidCallback onViewDetails;

  const _CoachCard({
    required this.coach,
    required this.onSuspend,
    required this.onUnsuspend,
    required this.onViewDetails,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'active':    return Colors.green;
      case 'pending':   return Colors.blue;
      case 'suspended': return Colors.orange;
      default:          return Colors.grey;
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = coach.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFF3E5F5),
                child: Icon(Icons.person, color: Color(0xFF9C27B0)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPending ? 'Pending Invitation' : coach.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(coach.email,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(coach.phone ?? 'N/A',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(coach.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  coach.status,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pending info
          if (isPending) ...[
            Text('Invitation Sent',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(
              coach.invitationSent != null
                  ? _formatDate(coach.invitationSent!)
                  : '—',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text('Waiting for coach to accept invitation',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 12),
          ],

          // Active stats
          if (!isPending) ...[
            Row(
              children: [
                _InfoCell(
                    label: 'Joined',
                    value: coach.hireDate != null
                        ? _formatDate(coach.hireDate!)
                        : '—'),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('View Details'),
                ),
              ),
              if (!isPending) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: coach.status == 'suspended'
                      ? OutlinedButton.icon(
                          onPressed: onUnsuspend,
                          icon: const Icon(Icons.play_circle_outline,
                              size: 16, color: Colors.green),
                          label: const Text('Unsuspend',
                              style: TextStyle(color: Colors.green)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: onSuspend,
                          icon: const Icon(Icons.pause_circle_outline,
                              size: 16),
                          label: const Text('Suspend'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// Info Cell

class _InfoCell extends StatelessWidget {
  final String label, value;
  const _InfoCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}