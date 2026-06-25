import 'package:flutter/material.dart';

class PasswordResetSuccessPage extends StatelessWidget {
  final bool isLoggedIn;
  const PasswordResetSuccessPage({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 64,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Password Reset',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Your password has been reset successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Color(0xFF388E3C)),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLoggedIn) {
                      Navigator.of(context)
                        ..pop() // close this success page
                        ..pop(); // close the forgot-password flow, back to profile
                    } else {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}