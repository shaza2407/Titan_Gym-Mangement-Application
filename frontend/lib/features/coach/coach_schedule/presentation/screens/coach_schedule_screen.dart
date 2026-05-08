import 'package:flutter/material.dart';
import 'package:frontend/features/coach/coach_schedule/presentation/widgets/request_class_bottom_sheet.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
import '../widgets/schedule_day_card.dart';
import 'package:frontend/features/coach/coach_dashboard/presentation/widgets/stats_section.dart';
// import '../widgets/request_class_bottom_sheet.dart';
import '../widgets/MyClassesListView.dart';
import '../widgets/RequestsListView.dart';

class CoachSchedulePage extends StatefulWidget {
  final int coachId;
  const CoachSchedulePage({super.key, required this.coachId});

  @override
  State<CoachSchedulePage> createState() => _CoachSchedulePageState();
}

class _CoachSchedulePageState extends State<CoachSchedulePage> with TickerProviderStateMixin {
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
            Text("My Schedule & Classes", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("View timetable and manage class requests", style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                // Note: You'd fetch these numbers from your /schedule/stats API
                const StatsSection(stats: [
                  StatItemData(icon: Icon(Icons.calendar_month, color: Colors.purple), label: "Weekly Classes", number: 8),
                  StatItemData(icon: Icon(Icons.people_alt_outlined, color: Colors.blue), label: "Total Students", number: 111),
                  StatItemData(icon: Icon(Icons.access_time, color: Colors.orange), label: "Pending Requests", number: 1),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => RequestClassScreen(coachId: widget.coachId),
                      );
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text("Request New Class Time", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A0E21),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  // --- TAB 1: SCHEDULE ---
  Widget _buildScheduleTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text("This Week's Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        ScheduleDayCard(dayName: "Monday"),
        ScheduleDayCard(dayName: "Tuesday"),
      ],
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