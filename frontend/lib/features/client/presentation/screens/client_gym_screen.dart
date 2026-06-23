import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/client_gym_controller.dart';
import '../../domain/gym_model.dart';
import '../widgets/client_bottom_nav.dart';

class ClientGymScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onBack;

  const ClientGymScreen({super.key, required this.token, this.onBack});

  @override
  State<ClientGymScreen> createState() => _ClientGymScreenState();
}

class _ClientGymScreenState extends State<ClientGymScreen> {
  late ClientGymController _ctrl;

  // 0 = Announcements, 1 = Schedule
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = ClientGymController();
    _ctrl.loadAll(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<ClientGymController>(
        builder: (context, ctrl, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: widget.onBack ?? () => Navigator.pop(context),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ctrl.gym?.gymName ?? 'My Gym',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Gym Information',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            body: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ctrl.errorMessage != null
                ? _buildError(ctrl)
                : _buildBody(ctrl),
            bottomNavigationBar: ClientBottomNav(
              currentIndex: 0, // reached from Home actions
              onTap: (i) => Navigator.pop(context, i == 0 ? null : i),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(ClientGymController ctrl) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(ctrl.errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ctrl.loadAll(widget.token),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Everything lives in ONE scrollable list — gym card, toggle, and active
  // tab content all scroll together, so the gym card naturally scrolls
  // away instead of staying pinned.
  Widget _buildBody(ClientGymController ctrl) {
    final weekly = ctrl.weeklySchedule;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (ctrl.gym != null) _buildGymDetailsCard(ctrl),
        if (ctrl.gym != null) const SizedBox(height: 16),

        _buildTabToggle(ctrl),
        const SizedBox(height: 16),

        if (_selectedTab == 0)
          ..._buildAnnouncementsContent(ctrl)
        else
          ..._buildScheduleContent(weekly),
      ],
    );
  }

  // ── Gym Details Card ───────────────────────────────────────────────────
  Widget _buildGymDetailsCard(ClientGymController ctrl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gym Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          _buildDetailRow(
            Icons.location_on_outlined,
            'Location',
            ctrl.gym!.location,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.access_time_outlined,
            'Operating Hours',
            '${_formatTime(ctrl.gym!.openingHours)} - ${_formatTime(ctrl.gym!.closingHours)}',
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.fitness_center_outlined,
            'Gym Type',
            _capitalize(ctrl.gym!.gymType) ?? ctrl.gym!.gymType,
          ),
        ],
      ),
    );
  }

  // ── Tab Toggle (replaces TabBar/TabController) ────────────────────────
  Widget _buildTabToggle(ClientGymController ctrl) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleItem(
              index: 0,
              icon: Icons.notifications_outlined,
              label: 'Announcements',
              badgeCount: ctrl.announcements.length,
            ),
          ),
          Expanded(
            child: _buildToggleItem(
              index: 1,
              icon: Icons.calendar_month_outlined,
              label: 'This Week Schedule',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.black : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.black : Colors.grey,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Announcements Content ─────────────────────────────────────────────
  List<Widget> _buildAnnouncementsContent(ClientGymController ctrl) {
    if (ctrl.announcements.isEmpty) {
      return [
        _buildEmpty(
          Icons.notifications_off_outlined,
          'No Announcements',
          'Check back later for updates from your gym',
        ),
      ];
    }
    return ctrl.announcements.map((a) => _buildAnnouncementCard(a)).toList();
  }

  Widget _buildAnnouncementCard(AnnouncementModel a) {
    final receiverLower = a.reciever.toLowerCase();
    // Hide the receiver badge if it's just "Client" or "Clients and Coaches" —
    // not useful info from the client's own perspective.
    final showReceiver = !receiverLower.contains('client');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEDFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  color: Color(0xFF4F46E5),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  a.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            a.content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showReceiver)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        a.reciever,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
              Text(
                _formatDate(a.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Schedule Content ──────────────────────────────────────────────────
  List<Widget> _buildScheduleContent(Map<String, List<GymClassModel>> weekly) {
    if (weekly.isEmpty) {
      return [
        _buildEmpty(
          Icons.calendar_today_outlined,
          'No Classes This Week',
          'Check back later for scheduled classes',
        ),
      ];
    }
    return ClientGymController.dayNames
        .map((day) => _buildDaySection(day, weekly[day] ?? []))
        .toList();
  }

  Widget _buildDaySection(String day, List<GymClassModel> classes) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _capitalize(day) ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: classes.isEmpty
                      ? Colors.grey.shade100
                      : const Color(0xFFF0F0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  classes.isEmpty
                      ? 'No classes'
                      : '${classes.length} class${classes.length == 1 ? '' : 'es'}',
                  style: TextStyle(
                    color: classes.isEmpty
                        ? Colors.grey
                        : const Color(0xFF4F46E5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (classes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            ...classes.map((c) => _buildClassRow(c)),
          ],
        ],
      ),
    );
  }

  Widget _buildClassRow(GymClassModel c) {
    final color = c.isFull
        ? Colors.red
        : c.fillRatio > 0.8
        ? Colors.orange
        : const Color(0xFF4CAF50);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 70,
            child: Text(
              _formatTime(c.startTime),
              style: const TextStyle(
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 2, height: 40, color: const Color(0xFFF0F0F0)),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      c.coachName ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${c.duration} min',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Capacity badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${c.currentClients}/${c.maxClients}',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEDFE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmpty(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';

    final parts = time.split(':');
    final hour = int.tryParse(parts[0]);
    if (hour == null) return time;

    final min = parts.length > 1
        ? parts[1]
        : '00'; // default minutes if missing
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour > 12
        ? hour - 12
        : hour == 0
        ? 12
        : hour;
    return '${h.toString().padLeft(2, '0')}:${min.padLeft(2, '0')} $period';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String? _capitalize(String? s) {
    if (s == null || s.isEmpty) return null;
    return s[0].toUpperCase() + s.substring(1);
  }
}
