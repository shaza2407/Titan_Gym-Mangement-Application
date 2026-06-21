import 'package:flutter/material.dart';
import '../data/admin_repository.dart';
import 'invite_member_screen.dart';
import 'coach_detail_screen.dart';
import '../data/gym_repository.dart';

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
  late Future<CoachListResponse> _future;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = AdminApiService.fetchCoaches(widget.gym.gymID, widget.token);
  }

  void _refresh() => setState(() => _load());

  List<CoachListItem> _filtered(List<CoachListItem> coaches) {
    return coaches.where((c) {
      final matchFilter =
          _selectedFilter == 'all' || c.status == _selectedFilter;
      final matchSearch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();
  }

  Future<void> _suspend(int coachId) async {
    try {
      await AdminApiService.suspendCoach(widget.gym.gymID, coachId, widget.token);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coach suspended successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coach Management', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('View and manage gym coaches', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
              child: const Icon(Icons.person_add, color: Colors.white, size: 20),
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
              _refresh();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<CoachListResponse>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          final filtered = _filtered(data.coaches);

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─ Stats Row
                Row(
                  children: [
                    _StatCard(
                        label: 'Total Coaches',
                        value: '${data.total}',
                        icon: Icons.sports_gymnastics),
                    const SizedBox(width: 8),
                    _StatCard(
                        label: 'Active',
                        value: '${data.active}',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF9C27B0)),
                    const SizedBox(width: 8),
                    _StatCard(
                        label: 'Pending',
                        value: '${data.pending}',
                        icon: Icons.person_add_outlined,
                        color: Colors.orange),
                  ],
                ),
                const SizedBox(height: 16),

                // ─ Search
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
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
                ),
                const SizedBox(height: 12),

                // ─ Filter Tabs
                _FilterRow(
                  selected: _selectedFilter,
                  onSelect: (v) => setState(() => _selectedFilter = v),
                ),
                const SizedBox(height: 16),

                // ─ Coach Cards
                if (filtered.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No coaches found',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ...filtered.map((c) => _CoachCard(
                        coach: c,
                        onSuspend: () => _suspend(c.id),
                        onViewDetails: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CoachDetailScreen(coach: c),
                            ),
                          );
                        },
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final filters = [
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
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
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

// ─── Stat Card

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

// ─── Coach Card ───

class _CoachCard extends StatelessWidget {
  final CoachListItem coach;
  final VoidCallback onSuspend;
  final VoidCallback onViewDetails;

  const _CoachCard({
    required this.coach,
    required this.onSuspend,
    required this.onViewDetails,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.blue;
      case 'suspended':
        return Colors.orange;
      default:
        return Colors.grey;
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
          // ── Header ──
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

          // ── Pending info
          if (isPending) ...[
            Text('Invitation Sent',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(
              coach.invitationSent != null
                  ? _formatDate(coach.invitationSent!)
                  : '—',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text('Waiting for coach to accept invitation',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 12),
          ],

          // ─ Active stats
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

          // ── Action Buttons
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
                  child: OutlinedButton.icon(
                    onPressed: onSuspend,
                    icon: const Icon(Icons.pause_circle_outline, size: 16),
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

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

class _InfoCell extends StatelessWidget {
  final String label, value;
  const _InfoCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}