// Components
//  ├── HeaderSection (appbar)
//  ├── StatsSection (body)
//  ├── UpcomingClassesSection (body)
//  ├── QuickActionsSection (body)
//  └── BottomNavBar (bottomNavigationBar)


import 'package:flutter/material.dart';
import 'package:frontend/features/coach/coach_dashboard/presentation/widgets/stats_section.dart';
import 'package:frontend/features/coach/coach_dashboard/presentation/widgets/upcoming_classes_section.dart';
import 'package:frontend/features/coach/coach_dashboard/presentation/widgets/quick_actions_section.dart';

class CoachDashboardScreen extends StatelessWidget{
  const CoachDashboardScreen({super.key});

  @override
Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Matches the clean background of the design
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 16), // Space under the app bar
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
              SizedBox(height: 32), // Big gap
              UpcomingClassesSection(),
              SizedBox(height: 32), // Big gap
              QuickActionsSection(),
              SizedBox(height: 32), // Bottom padding so it doesn't hug the nav bar
            ],
          ),
        ),
      ),    
    );
  }
}


