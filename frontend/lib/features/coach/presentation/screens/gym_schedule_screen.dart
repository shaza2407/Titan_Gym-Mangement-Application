import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/gym_schedule_controller.dart';
import '../widgets/gym_schedule_list_view.dart';

class GymScheduleScreen extends StatefulWidget {
  final String token;
  final int gymId;
  final String gymName;

  const GymScheduleScreen({
    super.key,
    required this.token,
    required this.gymId,
    required this.gymName,
  });

  @override
  State<GymScheduleScreen> createState() => _GymScheduleScreenState();
}

class _GymScheduleScreenState extends State<GymScheduleScreen> {
  late final GymScheduleController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = GymScheduleController();
    _ctrl.addListener(_onError);
    _ctrl.loadGymSchedule(widget.token, widget.gymId);
  }

  void _onError() {
    if (_ctrl.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ctrl.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      _ctrl.errorMessage = null;
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
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Weekly class timetable',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            body: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () =>
                        ctrl.loadGymSchedule(widget.token, widget.gymId),
                    child: GymScheduleListView(ctrl: ctrl),
                  ),
            // No bottomNavigationBar — back arrow or swipe returns to Gyms tab
          );
        },
      ),
    );
  }
}
