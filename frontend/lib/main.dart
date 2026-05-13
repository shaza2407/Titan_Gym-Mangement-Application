import 'package:flutter/material.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/coach/coach_dashboard/presentation/screens/coach_dashboard_screen.dart';
import 'features/auth/presentation/login_screen.dart';   // 👈 add

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      routes: {
        '/login': (context) => LoginScreen(),        
        '/signup': (context) => SignupScreen(),
        '/coach-dashboard': (context) => const CoachDashboardScreen(coachId: 2),
        },
      home: LoginScreen(),   // 👈 start from login
    );
  }
}