import 'package:flutter/material.dart';
import '../controller/signup_controller.dart';
import 'package:provider/provider.dart';


class SignupScreen extends StatelessWidget {
  final controller = SignupController();

  SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Consumer<SignupController>(
              builder: (context, ctrl, _) => Column(                
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/login'),
                    child: Icon(Icons.arrow_back),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF4F46E5),
                      child: Icon(Icons.fitness_center, color: Colors.white, size: 36),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Title
                  Center(child: Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
                  Center(child: Text('Join Titan Fitness Center', style: TextStyle(color: Colors.grey))),
                  SizedBox(height: 32),

                  // Fields
                  _buildField('Full Name', 'Enter your full name', ctrl.fullNameController),
                  _buildField('Email', 'Enter your email', ctrl.emailController),
                  _buildField('Phone Number', 'Enter your phone number', ctrl.phoneController),

                  // Role Dropdown
                  Text('I am a', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: ctrl.selectedRole,
                    hint: Text('Select your role'),
                    items: ctrl.roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (String? value) => ctrl.setRole(value),  
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                  SizedBox(height: 16),

                  _buildField('Password', 'Create a password', ctrl.passwordController, obscure: true),
                  _buildField('Confirm Password', 'Confirm your password', ctrl.confirmController, obscure: true),

                  // Error
                  if (ctrl.errorMessage != null)
                    Text(ctrl.errorMessage!, style: TextStyle(color: Colors.red)),

                  SizedBox(height: 24),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: ctrl.isLoading ? null : () => ctrl.signUp(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: ctrl.isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Sign Up', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  // At the bottom, after the Sign Up button
                  SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account? "),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/login'),
                          child: 
                            _HoverTextButton(label: 'Sign in',onTap: () => Navigator.pushNamed(context, '/login'),),

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
    );
  }

  Widget _buildField(String label, String hint, TextEditingController ctrl, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        SizedBox(height: 16),
      ],
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


