import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends StatelessWidget {
  final controller = LoginController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Scaffold(
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
              child: Consumer<LoginController>(
                builder: (context, ctrl, _) => Column(
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
                      controller: ctrl.emailController,
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        filled: true,
                        fillColor: Colors.grey[100],
                        errorText: ctrl.fieldErrors['email'],
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
                        Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                        _HoverTextButton(
                          label: 'Forgot password?',
                          onTap: () => Navigator.pushNamed(context, '/forgot-password'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: ctrl.passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        filled: true,
                        fillColor: Colors.grey[100],
                        errorText: ctrl.fieldErrors['password'],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    // API error message
                    if (ctrl.errorMessage != null) ...[
                      SizedBox(height: 12),
                      Text(ctrl.errorMessage!, style: TextStyle(color: Colors.red, fontSize: 13)),
                    ],

                    SizedBox(height: 24),

                    // Sign In button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: ctrl.isLoading ? null : () => ctrl.signIn(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: ctrl.isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Sign In', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Sign up link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? "),
                          _HoverTextButton(
                            label: 'Sign up',
                            onTap: () => Navigator.pushNamed(context, '/signup'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
            color: _isPressed ? const Color(0xFF3730A3) : const Color(0xFF4F46E5),
            decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
            decorationColor: _isPressed ? const Color(0xFF3730A3) : const Color(0xFF4F46E5),
          ),
        ),
      ),
    );
  }
}