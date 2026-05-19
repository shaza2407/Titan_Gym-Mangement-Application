import 'package:flutter/material.dart';
import 'package:frontend/features/coach/coach_dashboard/presentation/layouts/coach_layout.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/client/presentation/screens/client_dashboard_screen.dart';
import 'features/client/presentation/screens/client_profile_screen.dart';
import 'features/auth/presentation/verify_email_page.dart';
import 'features/auth/presentation/forget_password_page.dart';
import 'features/admin/presentation/admin_dashboard_screen.dart';
import 'features/shared/api_constants.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConstants.initialize();
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
        '/forgot-password': (context) => ForgotPasswordPage(),
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
          final token = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => CoachMainWrapper(token:token),
          );
        }
        if (settings.name == '/verify-email') {
          final email = settings.arguments as String;
          return MaterialPageRoute(builder: (_) => VerifyEmailPage(email: email),);
        }
        
        if (settings.name == '/admin-dashboard') {
          final token = settings.arguments as String;
          return MaterialPageRoute(builder: (_) => AdminDashboardScreen(token: token),);
        }
  
  return null;
},
      home: LoginScreen(),
    );
  }
}