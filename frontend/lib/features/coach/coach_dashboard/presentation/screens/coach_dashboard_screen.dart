// Components
//  ├── HeaderSection (appbar)
//  ├── StatsSection (body)
//  ├── UpcomingClassesSection (body)
//  ├── QuickActionsSection (body)
//  └── BottomNavBar (bottomNavigationBar)

import 'package:flutter/material.dart';
import 'package:frontend/features/coach/shared/presentation/stats_section.dart';
import 'package:frontend/features/coach/coach_dashboard/presentation/widgets/upcoming_classes_section.dart';
import 'package:frontend/features/coach/coach_dashboard/presentation/widgets/quick_actions_section.dart';
import 'package:frontend/features/coach/shared/data/coach_api_service.dart';

class CoachDashboardScreen extends StatelessWidget {
  final int coachId;
  const CoachDashboardScreen({super.key, required this.coachId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white, // Matches the clean background of the design
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16), // Space under the app bar

              FutureBuilder<DashboardStats>(
                future: CoachApiService.fetchDashboardStats(coachId),
                initialData: DashboardStats(
                  weeklyClasses: 0,
                  totalClients: 0,
                  pendingRequests: 0,
                ),
                builder: (context, snapshot) {
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
                        icon: Icon(
                          Icons.people_alt_outlined,
                          color: Colors.blue,
                        ),
                        label: "Total Clients",
                        number: stats.totalClients,
                      ),
                      // StatItemData(
                      //   icon: const Icon(Icons.apartment_outlined, color: Colors.green),
                      //   label: "Active Gyms",
                      //   number: stats.activeGyms,
                      // ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              UpcomingClassesSection(coachId: coachId),
              const SizedBox(height: 32),
              QuickActionsSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
