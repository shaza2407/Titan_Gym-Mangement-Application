import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/forget_password_controller.dart';
import 'password_reset_success_screen.dart';

class ForgotPasswordPage extends StatelessWidget {
  final bool isLoggedIn;
  const ForgotPasswordPage({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ForgotPasswordController(),
      child: Consumer<ForgotPasswordController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ),
            body: SingleChildScrollView(
  padding: const EdgeInsets.all(24.0),
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // add top spacing to keep it centered when no keyboard
      SizedBox(height: MediaQuery.of(context).size.height * 0.1),
      
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lock_reset,
          size: 64,
          color: Colors.white,
        ),
      ),

      const SizedBox(height: 32),

      Text(
        controller.codeSent ? 'Enter Reset Code' : 'Forgot Password',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 16),

      Text(
        controller.codeSent
            ? 'Enter the 6-digit code sent to ${controller.sentEmail} and your new password.'
            : 'Enter your email and we will send you a reset code.',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      ),

      const SizedBox(height: 32),

      if (!controller.codeSent)
        TextField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

      if (controller.codeSent) ...[
        TextField(
          controller: controller.codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 16,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 16),

        TextField(
          controller: controller.passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 16),

        TextField(
          controller: controller.confirmController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],

      const SizedBox(height: 16),

      if (controller.errorMessage != null)
        Text(
          controller.errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),

      const SizedBox(height: 16),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: controller.isLoading
              ? null
              : () async {
                  if (!controller.codeSent) {
                    controller.sendCode();
                    return;
                  }
                  final success = await controller.resetPassword();
                  if (success && context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PasswordResetSuccessPage(
                          isLoggedIn: isLoggedIn,
                        ),
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: controller.isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  controller.codeSent ? 'Reset Password' : 'Send Code',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
        ),
      ),

      // bottom padding so button clears the keyboard
      SizedBox(height: MediaQuery.of(context).size.height * 0.05),
    ],
  ),
),
          );
        },
      ),
    );
  }
}
