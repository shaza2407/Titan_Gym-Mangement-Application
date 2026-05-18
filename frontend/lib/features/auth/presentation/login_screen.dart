import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';

class LoginScreen extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }
  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: Color(0xFFEEF0F8),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Container(
            padding: EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF4F46E5),
                    child: Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Title
                Center(
                  child: Text(
                    'Titan',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Text(
                    'Gym Community Management System',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                SizedBox(height: 32),

                // Email
                Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Password',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(             
                      onTap: () => Navigator.pushNamed(context, '/forgot-password'),child: Text('Forgot password?',style: TextStyle(color: Color(0xFF4F46E5)),
                    )),
                  ],
                ),
                SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Sign In button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      final email = emailController.text.trim();
                      final password = passwordController.text;

                      if (email.isEmpty || password.isEmpty) return;

                      try {
                        final signinRes = await http.post(
                          Uri.parse("$baseUrl/auth/signin"),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'email': email,
                            'password': password,
                          }),
                        );

                        if (signinRes.statusCode != 200) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                jsonDecode(signinRes.body)['detail'] ??
                                    'Sign in failed',
                              ),
                            ),
                          );
                          return;
                        }

                        final signinData = jsonDecode(signinRes.body);
                        final token = signinData['access_token'] as String;
                        final role = signinData['role'] as String;
                        if (role == 'admin') {
                          Navigator.pushReplacementNamed(context,'/admin-dashboard', arguments: token,); 
                          return;
                        }
                        
                        if (role == 'coach') {
                          Navigator.pushReplacementNamed(
                            context,
                            '/coach-dashboard',
                          );
                          return;
                        }

                        if (role == 'client') {
                          // Step 3 — Check if connected to gym
                          final meRes = await http.get(
                            Uri.parse('$baseUrl/client/me'),
                            headers: {
                              'Content-Type': 'application/json',
                              'Authorization': 'Bearer $token',
                            },
                          );

                          if (meRes.statusCode == 200) {
                            final meData = jsonDecode(meRes.body);
                            final isConnected = meData['is_connected'] as bool;

                            if (isConnected) {
                              Navigator.pushReplacementNamed(
                                context,
                                '/client-dashboard',
                                arguments: token,
                              );
                            } else {
                              Navigator.pushReplacementNamed(
                                context,
                                '/client-profile-only',
                                arguments: token,
                              );
                            }
                          }
                          return;
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text('Sign In',style: TextStyle(fontSize: 16, color: Colors.white),),
                  ),
                ),
                SizedBox(height: 16),

                // Sign up link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/signup'),
                        child: Text(
                          'Sign up',
                          style: TextStyle(
                            color: Color(0xFF4F46E5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
