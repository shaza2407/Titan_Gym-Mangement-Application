import 'package:flutter/material.dart';

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
                    child: Icon(Icons.fitness_center, color: Colors.white, size: 36),
                  ),
                ),
                SizedBox(height: 16),

                // Title
                Center(child: Text('Titan', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
                Center(child: Text('Gym Community Management System', style: TextStyle(color: Colors.grey))),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                SizedBox(height: 16),

                // Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Forgot password?', style: TextStyle(color: Color(0xFF4F46E5))),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                SizedBox(height: 24),

                // Sign In button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Sign In', style: TextStyle(fontSize: 16, color: Colors.white)),
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
                        child: Text('Sign up', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
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