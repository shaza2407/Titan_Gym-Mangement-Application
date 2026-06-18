import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/logout_button.dart';
import '../../../coach/presentation/screens/coach_ui_utils.dart';
import '../controllers/coach_dashboard_controller.dart';
import '../../domain/coach_dashboard_model.dart';
import 'coach_schedule_screen.dart';
import 'coach_profile_screen.dart';

class CoachDashboardScreen extends StatefulWidget {
  final String token;
  const CoachDashboardScreen({super.key, required this.token});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  int _currentIndex = 0;
  late final CoachDashboardController _ctrl;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _ctrl = CoachDashboardController();
    _ctrl.loadAll(widget.token); // called once — not on every rebuild

    // Built once. IndexedStack keeps every tab mounted, so switching tabs
    // never re-triggers initState or re-fetches data, and scroll position /
    // in-progress edits on Schedule & Profile are preserved.
    _tabs = [
      ChangeNotifierProvider.value(
        value: _ctrl,
        child: Consumer<CoachDashboardController>(
          builder: (context, ctrl, _) => _buildHomeTab(ctrl),
        ),
      ),
      CoachScheduleScreen(
        token: widget.token,
        onBack: () => setState(() => _currentIndex = 0),
      ),
      CoachProfileScreen(
        token: widget.token,
        onBack: () => setState(() => _currentIndex = 0),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoachColors.background,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: CoachColors.primary,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }

  Widget _buildHomeTab(CoachDashboardController ctrl) {
    final stats = ctrl.stats;

    // Full-screen spinner only on the very first load. A later refresh
    // (pull-to-refresh) keeps stale content visible with the refresh
    // spinner on top, instead of blanking the whole tab.
    if (ctrl.isLoading && stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _ctrl.loadAll(widget.token),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Row(
                children: [
                  StatCard(icon: Icons.calendar_today_outlined, value: '${stats?.weeklyClasses ?? 0}', label: 'Weekly\nClasses', color: CoachColors.primary),
                  const SizedBox(width: 12),
                  StatCard(icon: Icons.people_outline, value: '${stats?.totalStudents ?? 0}', label: 'Total\nStudents', color: CoachColors.success),
                  const SizedBox(width: 12),
                  StatCard(icon: Icons.fitness_center_outlined, value: '${stats?.activeGyms ?? 0}', label: 'Active\nGyms', color: CoachColors.warning),
                ],
              ),
              const SizedBox(height: 16),
              _buildUpcomingSection(ctrl),
              const SizedBox(height: 16),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color.fromARGB(255, 206, 132, 28),
              child: const Icon(Icons.fitness_center, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coach Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Welcome back, Coach!', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Stack(
              children: [
                IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
              ],
            ),
            IconButton(icon: const Icon(Icons.logout_outlined), onPressed: () => showLogoutDialog(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingSection(CoachDashboardController ctrl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Classes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(_todayLabel(), style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          if (ctrl.upcoming.isEmpty)
            const EmptyState(
              title: 'No classes today',
              subtitle: "Nothing on the books for today.",
              icon: Icons.free_breakfast_outlined,
            )
          else
            ...ctrl.upcoming.map(_buildUpcomingCard),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(CoachUpcomingClassModel c) {
    final isFull = c.currentClients >= c.maxClients;
    final ratio = c.maxClients == 0 ? 0.0 : c.currentClients / c.maxClients;
    final capacityColor = isFull ? CoachColors.danger : (ratio > 0.8 ? CoachColors.warning : CoachColors.success);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: CoachColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.calendar_month, color: CoachColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(c.gymName ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatTime(c.startTime), style: const TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: capacityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${c.currentClients}/${c.maxClients}', style: TextStyle(color: capacityColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('Manage your coaching activities', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          _buildActionItem(Icons.calendar_month_outlined, 'My Schedule & Classes', 'View schedule and manage class requests', () => setState(() => _currentIndex = 1)),
          _buildActionItem(Icons.person_outline, 'My Profile', 'Update your coach information', () => setState(() => _currentIndex = 2)),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: const Color.fromARGB(255, 206, 132, 28), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = ['', 'January','February','March','April','May','June','July','August','September','October','November','December'];
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${days[now.weekday - 1]}, ${months[now.month]} ${now.day}, ${now.year}';
  }
}