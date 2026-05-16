import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/client/presentation/screens/client_dashboard_screen.dart';
import 'features/client/presentation/screens/client_profile_screen.dart';
import 'features/coach/coach_dashboard/presentation/screens/coach_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Titan Gym',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      routes: {
        '/login':  (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
      },
      // Routes that need arguments use onGenerateRoute
      onGenerateRoute: (settings) {
        if (settings.name == '/client-dashboard') {
          final token = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => ClientDashboardScreen(token: token),
          );
        }
        if (settings.name == '/client-profile-only') {
          final token = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => ClientProfileScreen(token: token),
          );
        }
        if (settings.name == '/coach-dashboard') {
          return MaterialPageRoute(
            builder: (_) => const CoachDashboardScreen(coachId: 2),
          );
        }
        return null;
      },
      home: LoginScreen(),
    );
  }
}