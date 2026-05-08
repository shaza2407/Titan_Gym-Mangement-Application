import 'package:flutter/material.dart';
// import your widgets here...

import 'package:frontend/features/coach/coach_schedule/presentation/widgets/schedule_day_card.dart';
import 'package:frontend/features/coach/coach_schedule/presentation/widgets/custom_tab_bar.dart';
import 'package:frontend/features/coach/coach_schedule/presentation/widgets/request_class_bottom_sheet.dart';
import 'package:frontend/features/coach/coach_dashboard/presentation/widgets/stats_section.dart';
class CoachSchedulePage extends StatelessWidget {
  const CoachSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatsSection(
              stats: [
                StatItemData(
                  icon: const Icon(Icons.calendar_month, color: Colors.purple),
                  label: "Weekly Classes",
                  number: 8,
                ),
                StatItemData(
                  icon: const Icon(Icons.people_alt_outlined, color: Color(0xFF2196F3)),
                  label: "Total Students",
                  number: 106,
                ),
                StatItemData(
                  icon: const Icon(Icons.apartment_outlined, color: Color(0xFF4CAF50)),
                  label: "Active Gyms",
                  number: 2,
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // Allows the sheet to take up more screen space for the keyboard
                    backgroundColor: Colors.transparent, // Important: lets our rounded corners show!
                    builder: (context) => const RequestClassScreen(coachId: 2,),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Request New Class Time",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF0A0E21,
                  ), // Dark navy/black color
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const CustomTabBar(),
            const SizedBox(height: 24),

            const Text(
              "This Week's Schedule",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            const ScheduleDayCard(dayName: "Monday"),
            const ScheduleDayCard(dayName: "Tuesday"),
            const ScheduleDayCard(dayName: "Wednesday"),
          ],
        ),
      ),
    );
  }
}
