import 'package:flutter/material.dart';
import 'package:frontend/features/coach/shared/presentation/coach_app_bar.dart';
import 'package:frontend/features/coach/shared/presentation/stats_section.dart';
import 'package:frontend/features/coach/coach_dashboard/presentation/widgets/upcoming_classes_section.dart';
import 'package:frontend/features/coach/coach_dashboard/presentation/widgets/quick_actions_section.dart';
import 'package:frontend/features/coach/shared/data/coach_api_service.dart';

class CoachDashboardScreen extends StatelessWidget {
  final String token;
  const CoachDashboardScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: const HeaderSection(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16), 

              FutureBuilder<DashboardStats>(
                future: CoachApiService.fetchDashboardStats(token),
                initialData: DashboardStats(
                  weeklyClasses: 0,
                  totalClients: 0,
                  pendingRequests: 0,
                ),
                builder: (context, snapshot) {
                  final stats = snapshot.data ??
                      DashboardStats(
                        weeklyClasses: 0,
                        totalClients: 0,
                        pendingRequests: 0,
                      );
                  return StatsSection(
                    stats: [
                      StatItemData(
                        icon: const Icon(Icons.calendar_month, color: Colors.purple),
                        label: "Weekly Classes",
                        number: stats.weeklyClasses,
                      ),
                      StatItemData(
                        icon: const Icon(Icons.people_alt_outlined, color: Colors.blue),
                        label: "Total Clients",
                        number: stats.totalClients,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              UpcomingClassesSection(token: token),
              const SizedBox(height: 32),
              QuickActionsSection( token: token),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}