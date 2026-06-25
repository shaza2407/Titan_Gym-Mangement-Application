//done
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/client_management_controller.dart';
import '../../domain/gym_model.dart';
import '../../domain/client_model.dart';
import 'invite_member_screen.dart';
import 'client_detail_screen.dart';
import 'renew_screen.dart';

class ClientManagementScreen extends StatefulWidget {
  final GymModel gym;
  final String token;
  final void Function(int)? onTabChange;

  const ClientManagementScreen({
    super.key,
    required this.gym,
    required this.token,
    this.onTabChange,
  });

  @override
  State<ClientManagementScreen> createState() =>
      _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  late final ClientManagementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClientManagementController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadClients(
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

  Future<void> _suspend(int memberId) async {
    final success = await _controller.suspendClient(
      gymId:    widget.gym.gymID,
      memberId: memberId,
      token:    widget.token,
    );
    if (!mounted) return;
    if (success) {
      await _controller.loadClients(
          gymId: widget.gym.gymID, token: widget.token);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member suspended successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.errorMessage ?? 'Failed')),
      );
    }
  }

  Future<void> _unsuspend(int memberId) async {
    final errorMsg = await _controller.unsuspendClient(
      gymId:    widget.gym.gymID,
      memberId: memberId,
      token:    widget.token,
    );
    if (!mounted) return;
    if (errorMsg == null) {
      await _controller.loadClients(
          gymId: widget.gym.gymID, token: widget.token);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Member unsuspended successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.grey),
      );
    }
  }

  Future<void> _cancelInvitation(String email) async {
    final success = await _controller.cancelInvitation(
      gymId: widget.gym.gymID,
      email: email,
      token: widget.token,
    );
    if (!mounted) return;
    if (success) {
      await _controller.loadClients(
          gymId: widget.gym.gymID, token: widget.token);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation cancelled')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_controller.errorMessage ?? 'Failed to cancel')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<ClientManagementController>(
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
                            Text(controller.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => controller.loadClients(
                                gymId: widget.gym.gymID,
                                token: widget.token,
                              ),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C63FF),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => controller.loadClients(
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
                                  child: Text('No clients found',
                                      style: TextStyle(color: Colors.grey)),
                                ),
                              )
                            else
                              ...controller.filtered.map(
                                (m) => _ClientCard(
                                  member:             m,
                                  onSuspend:          () => _suspend(m.id),
                                  onUnsuspend:        () => _unsuspend(m.id),
                                  onCancelInvitation: () => _cancelInvitation(m.email),
                                  onViewDetails: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ClientDetailScreen(member: m),
                                    ),
                                  ),
                                  onRenew: () => controller.loadClients(
                                    gymId: widget.gym.gymID,
                                    token: widget.token,
                                  ),
                                  gymId: widget.gym.gymID,
                                  token: widget.token,
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

  PreferredSizeWidget _buildAppBar(ClientManagementController controller) {
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
          Text('Client Management',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text('View and manage gym clients',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF),
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
                  gym: widget.gym,
                  token: widget.token,
                ),
              ),
            );
            controller.loadClients(
              gymId: widget.gym.gymID,
              token: widget.token,
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsRow(ClientManagementController controller) {
    final data = controller.data;
    return Row(
      children: [
        _StatCard(
          label: 'Total Clients',
          value: '${data?.total ?? 0}',
          icon: Icons.people_outline,
        ),
        const SizedBox(width: 8),
        _StatCard(
          label: 'Active',
          value: '${data?.active ?? 0}',
          icon: Icons.trending_up,
          color: const Color(0xFF6C63FF),
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

  Widget _buildSearchField(ClientManagementController controller) {
    return TextField(
      controller: controller.searchController,
      onChanged: controller.setSearch,
      decoration: InputDecoration(
        hintText: 'Search clients...',
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

// ── Filter Row ────────────────────────────────────────────────────────────────

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
      ('expired', 'Expired'),
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
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

// ── Stat Card ─────────────────────────────────────────────────────────────────

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

// ── Client Card ───────────────────────────────────────────────────────────────

class _ClientCard extends StatelessWidget {
  final ClientListItem member;
  final VoidCallback onSuspend;
  final VoidCallback onUnsuspend;
  final VoidCallback onCancelInvitation;
  final VoidCallback onViewDetails;
  final VoidCallback onRenew;
  final int gymId;
  final String token;

  const _ClientCard({
    required this.member,
    required this.onSuspend,
    required this.onUnsuspend,
    required this.onCancelInvitation,
    required this.onViewDetails,
    required this.onRenew,
    required this.gymId,
    required this.token,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'active':   return Colors.green;
      case 'pending':  return Colors.blue;
      case 'expired':  return Colors.red;
      default:         return Colors.grey;
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
    final isPending   = member.status == 'pending';
    final isSuspended = member.status == 'suspended';
    final isExpired   = member.status == 'expired';

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
                backgroundColor: Color(0xFFEDE9FF),
                child: Icon(Icons.person, color: Color(0xFF6C63FF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPending ? 'Pending Invitation' : member.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            member.email,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(member.phone ?? 'N/A',
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
                  color: _statusColor(member.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  member.status,
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
              member.invitationSent != null
                  ? _formatDate(member.invitationSent!)
                  : '—',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text('Waiting for client to accept invitation',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 12),
          ],

          // Active/Expired/Suspended stats
          if (!isPending) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoCell(
                    label: 'Subscription',
                    value: member.subscription ?? '—'),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Visits',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 11)),
                    Text('${member.visits ?? 0}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoCell(
                    label: 'Joined',
                    value: member.joined != null
                        ? _formatDate(member.joined!)
                        : '—'),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // View Details
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewDetails,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('View Details'),
            ),
          ),
          const SizedBox(height: 8),

          // Action Buttons
          if (!isPending)
            Row(
              children: [
                if (!isSuspended) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final renewed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RenewMembershipScreen(
                              member: member,
                              gymId:  gymId,
                              token:  token,
                            ),
                          ),
                        );
                        if (renewed == true) onRenew();
                      },
                      icon: const Icon(Icons.restart_alt, size: 16),
                      label: const Text('Renew'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (!isExpired)
                  Expanded(
                    child: isSuspended
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
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancelInvitation,
                icon: const Icon(Icons.cancel_outlined,
                    size: 16, color: Colors.red),
                label: const Text('Cancel Invitation',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Info Cell ─────────────────────────────────────────────────────────────────

class _InfoCell extends StatelessWidget {
  final String label, value;
  const _InfoCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Flexible(
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