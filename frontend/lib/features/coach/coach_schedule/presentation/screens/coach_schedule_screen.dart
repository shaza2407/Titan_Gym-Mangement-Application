import 'package:flutter/material.dart';
import 'package:frontend/features/coach/coach_schedule/presentation/widgets/request_class_bottom_sheet.dart';
import 'package:frontend/features/coach/shared/data/coach_api_service.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
import '../widgets/schedule_day_card.dart';
import 'package:frontend/features/coach/shared/presentation/stats_section.dart';
// import '../widgets/request_class_bottom_sheet.dart';
import '../widgets/MyClassesListView.dart';
import '../widgets/RequestsListView.dart';

class CoachScheduleScreen extends StatefulWidget {
  final int coachId;
  const CoachScheduleScreen({super.key, required this.coachId});

  @override
  State<CoachScheduleScreen> createState() => _CoachScheduleScreenState();
}

class _CoachScheduleScreenState extends State<CoachScheduleScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            Text(
              "My Schedule & Classes",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "View timetable and manage class requests",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Stats and Request Button (Static at the top)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                FutureBuilder<DashboardStats>(
                  future: CoachApiService.fetchScheduleStats(widget.coachId),
                  initialData: DashboardStats(weeklyClasses: 0, totalClients: 0, pendingRequests: 0),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                  final stats =
                  snapshot.data ??
                  DashboardStats(
                    weeklyClasses: 0,
                    totalClients: 0,
                    pendingRequests: 0,
                  );
                  return StatsSection(
                    stats: [
                      StatItemData(
                        icon: const Icon(
                          Icons.calendar_month,
                          color: Colors.purple,
                        ),
                        label: "Weekly Classes",
                        number: stats.weeklyClasses,
                      ),
                      StatItemData(
                        icon: const Icon(
                          Icons.people_alt_outlined,
                          color: Colors.blue,
                        ),
                        label: "Total Clients",
                        number: stats.totalClients,
                      ),
                      StatItemData(
                        icon: const Icon(
                          Icons.access_time,
                          color: Colors.orange,
                        ),
                        label: "Pending Requests",
                        number: stats.pendingRequests,
                      ),
                    ],
                  );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) =>
                            RequestClassScreen(coachId: widget.coachId),
                      );
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      "Request New Class Time",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A0E21),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. The Custom Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              // color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                // color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                // boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Schedule"),
                Tab(text: "My Classes"),
                Tab(text: "Requests"),
              ],
            ),
          ),

          // 3. The Tab Views (The scrollable lists)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildScheduleTab(),
                _buildMyClassesTab(),
                _buildRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return FutureBuilder<List<ClassSessionModel>>(
      future: CoachApiService.fetchWeeklySchedule(widget.coachId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const Center(child: Text("No classes scheduled this week."));

        final classes = snapshot.data!;
        Map<String, List<ClassSessionModel>> groupedClasses = {};
        for (var cls in classes) {
          groupedClasses.putIfAbsent(cls.date, () => []).add(cls);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "This Week's Schedule",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...groupedClasses.entries.map(
              (entry) =>
                  ScheduleDayCard(dayName: entry.key, classes: entry.value),
            ),
          ],
        );
      },
    );
  }

  // --- TAB 2: MY CLASSES ---
  Widget _buildMyClassesTab() {
    return MyClassesListView(coachId: widget.coachId);
  }

  // --- TAB 3: REQUESTS ---
  Widget _buildRequestsTab() {
    return RequestsListView(coachId: widget.coachId);
  }
}
