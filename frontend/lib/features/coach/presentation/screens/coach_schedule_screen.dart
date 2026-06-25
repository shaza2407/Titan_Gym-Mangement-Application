import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/coach_schedule_controller.dart';
import '../widgets/coach_ui_utils.dart'; // Adjust path if needed

// --- Import widgets ---
import '../widgets/schedule_stats_row.dart';
import '../widgets/request_class_button.dart';
import '../widgets/schedule_tabs.dart';
import '../widgets/upcoming_classes_carousel.dart';
import '../widgets/weekly_agenda_section.dart';
import '../widgets/class_requests_list.dart';

class CoachScheduleScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onBack;
  
  const CoachScheduleScreen({super.key, required this.token, this.onBack});

  @override
  State<CoachScheduleScreen> createState() => _CoachScheduleScreenState();
}

class _CoachScheduleScreenState extends State<CoachScheduleScreen> {
  late final CoachScheduleController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = CoachScheduleController();
    _ctrl.loadAll(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<CoachScheduleController>(
        builder: (context, ctrl, _) {
          return Scaffold(
            backgroundColor: CoachColors.background,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: widget.onBack,
                    )
                  : null,
              title: const Text(
                'Schedule & Requests',
                style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            body: ctrl.isLoading && ctrl.stats == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => ctrl.loadAll(widget.token),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ScheduleStatsRow(ctrl: ctrl),
                          const SizedBox(height: 24),
                          RequestClassButton(ctrl: ctrl, token: widget.token),
                          const SizedBox(height: 24),
                          ScheduleTabs(ctrl: ctrl),
                          const SizedBox(height: 20),
                          
                          if (ctrl.selectedTab == 0) ...[
                            UpcomingClassesCarousel(ctrl: ctrl, token: widget.token),
                            const SizedBox(height: 28),
                            WeeklyAgendaSection(ctrl: ctrl),
                          ],
                          if (ctrl.selectedTab == 1) ClassRequestsList(ctrl: ctrl, token: widget.token),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}