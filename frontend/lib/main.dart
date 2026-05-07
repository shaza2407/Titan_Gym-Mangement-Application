import 'package:flutter/material.dart';
import 'features/coach/coach_dashboard/presentation/screens/coach_dashboard_screen.dart ';
import 'features/coach/coach_schedule/presentation/screens/coach_schedule_page.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.white),
      ),
      // home: CoachSchedulePage(),
      home: const CoachDashboardScreen(),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

