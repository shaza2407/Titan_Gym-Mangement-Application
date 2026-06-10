import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';

class LoginScreen extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

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
                    Text('Password',style: TextStyle(fontWeight: FontWeight.bold),),
                    _HoverTextButton(label: 'Forgot password?',onTap: () => Navigator.pushNamed(context, '/forgot-password'),),
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
                          Uri.parse("${ApiConstants.baseUrl}/auth/signin"),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'email': email,
                            'password': password,
                          }),
                        );

                        if (signinRes.statusCode != 200) {
                          if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                jsonDecode(signinRes.body)['detail'] ??
                                    'Sign in failed',
                              ),
                            ),
                          );
                        }
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
                            arguments: token,
                          );
                          return;
                        }

                        if (role == 'client') {
                          // Step 3 — Check if connected to gym
                          final meRes = await http.get(
                            Uri.parse('${ApiConstants.baseUrl}/client/me'),
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
                        if (context.mounted) {
                        ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
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
                        child: 
                        _HoverTextButton(label: 'Sign up',onTap: () => Navigator.pushNamed(context, '/signup'),),
                        // Text(
                        //   'Sign up',
                        //   style: TextStyle(
                        //     color: Color(0xFF4F46E5),
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        // ),
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

class _HoverTextButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _HoverTextButton({required this.label, required this.onTap});

  @override
  State<_HoverTextButton> createState() => __HoverTextButtonState();
}

class __HoverTextButtonState extends State<_HoverTextButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: Text(
          widget.label,
          style: TextStyle(
            color: _isPressed
                ? const Color(0xFF3730A3)  
                : const Color(0xFF4F46E5), 
            decoration: _isHovered
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: _isPressed
                ? const Color(0xFF3730A3)
                : const Color(0xFF4F46E5),
          ),
        ),
      ),
    );
  }
}
