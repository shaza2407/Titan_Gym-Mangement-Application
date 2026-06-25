import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/gym_schedule_controller.dart';
import 'coach_dashboard_screen.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/gym_schedule_list_view.dart';

class GymScheduleScreen extends StatefulWidget {
  final String token;
  final int gymId;
  final String gymName;

  const GymScheduleScreen({super.key, required this.token, required this.gymId, required this.gymName});

  @override
  State<GymScheduleScreen> createState() => _GymScheduleScreenState();
}

class _GymScheduleScreenState extends State<GymScheduleScreen> {
  late final GymScheduleController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = GymScheduleController();
    _ctrl.loadGymSchedule(widget.token, widget.gymId);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<GymScheduleController>(
        builder: (context, ctrl, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.gymName} — Schedule',
                    style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text('Weekly class timetable', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            body: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => ctrl.loadGymSchedule(widget.token, widget.gymId),
                    child: GymScheduleListView(ctrl: ctrl),
                  ),
            bottomNavigationBar: CustomBottomNav(
              currentIndex: 2, 
              onTap: (i) {
                if (i == 2) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => CoachDashboardScreen(token: widget.token, initialIndex: i)),
                    (route) => false,
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}