import 'package:flutter/material.dart';
import 'package:frontend/features/coach/domain/coach_gyms_model.dart';
import 'package:frontend/features/coach/presentation/controllers/coach_gyms_controller.dart';
import 'package:frontend/features/coach/presentation/screens/gym_schedule_screen.dart';
import 'package:frontend/features/coach/presentation/screens/gym_announcements_screen.dart';
import 'package:provider/provider.dart';
import '../screens/coach_ui_utils.dart';

class CoachGymsScreen extends StatefulWidget {
  final String token;
  final VoidCallback onBack;

  const CoachGymsScreen({super.key, required this.token, required this.onBack});

  @override
  State<CoachGymsScreen> createState() => _CoachGymsScreenState();
}

class _CoachGymsScreenState extends State<CoachGymsScreen> {
  // 0 = Gyms, 1 = Announcements (all gyms)
  int _selectedTap = 0;
  late CoachGymsController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = CoachGymsController();
    _ctrl.loadAll(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<CoachGymsController>(
        builder: (context, ctrl, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: widget.onBack,
              ),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gyms', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Connected gyms and announcements', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            body: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => ctrl.loadAll(widget.token),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTabStats(ctrl),
                          const SizedBox(height: 24),
                          _buildSegmentedControl(),
                          const SizedBox(height: 20),
                          if (_selectedTap == 0) _buildGymsList(ctrl),
                          if (_selectedTap == 1) _buildAnnouncementsList(ctrl),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTabStats(CoachGymsController ctrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatBox(Icons.business, '${ctrl.myGyms.length}', 'Gyms', CoachColors.warning),
        const SizedBox(width: 12),
        _buildStatBox(Icons.people_outline, '${ctrl.totalClients}', 'Clients', const Color(0xFF3B82F6)),
        const SizedBox(width: 12),
        _buildStatBox(Icons.calendar_today_outlined, '${ctrl.totalClasses}', 'Classes', const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildStatBox(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _buildSegmentButton('My Gyms', 0),
          _buildSegmentButton('Announcements', 1),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String title, int index) {
    final isSelected = _selectedTap == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTap = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGymsList(CoachGymsController ctrl) {
    if (ctrl.myGyms.isEmpty) {
      return const EmptyState(
        title: 'No active gyms yet',
        subtitle: 'Once you join a gym, it will show up here.',
        icon: Icons.business,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ctrl.myGyms.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final gym = ctrl.myGyms[index];
        return GymCardWidget(
          gym: gym,
          onSchedule: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GymScheduleScreen(token: widget.token, gymId: gym.gymId, gymName: gym.gymName),
              ),
            );
          },
          // Navigates to a dedicated per-gym screen instead of
          // filtering the shared "Announcements" tab in place — that
          // tab is reserved for the all-gyms view.
          onAnnouncements: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GymAnnouncementsScreen(token: widget.token, gymId: gym.gymId, gymName: gym.gymName),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnnouncementsList(CoachGymsController ctrl) {
    if (ctrl.announcements.isEmpty) {
      return const EmptyState(
        title: 'No announcements',
        subtitle: 'Announcements from your gyms will show up here.',
        icon: Icons.notifications_none,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ctrl.announcements.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final ann = ctrl.announcements[index];
        return _buildAnnouncementCard(ann.title, ann.gymName, ann.date, ann.content);
      },
    );
  }

  Widget _buildAnnouncementCard(String title, String gymName, String date, String body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notifications_none, color: Color(0xFF0284C7), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(gymName, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                    ),
                  ],
                ),
              ),
              Text(formatDate(date), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(body, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

class GymCardWidget extends StatefulWidget {
  final CoachGymModel gym;
  final VoidCallback onSchedule;
  final VoidCallback onAnnouncements;

  const GymCardWidget({super.key, required this.gym, required this.onSchedule, required this.onAnnouncements});

  @override
  State<GymCardWidget> createState() => _GymCardWidgetState();
}

class _GymCardWidgetState extends State<GymCardWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final nextClassText = widget.gym.nextClass != null
        ? '${widget.gym.nextClass!.title} at ${widget.gym.nextClass!.startTime}'
        : 'No upcoming classes';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business, color: Color(0xFF8B5CF6)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.gym.gymName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(widget.gym.address, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMiniStat('Clients', '${widget.gym.clientsCount}'),
                    _buildMiniStat('Classes', '${widget.gym.classesCount}'),
                    _buildStatusBadge(widget.gym.status),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Next Class:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(nextClassText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isExpanded ? 'Hide Details' : 'View Details',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                  const SizedBox(width: 4),
                  Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onSchedule,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Schedule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onAnnouncements,
                      icon: const Icon(Icons.notifications_none, size: 18),
                      label: const Text('Announcements'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(status, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}