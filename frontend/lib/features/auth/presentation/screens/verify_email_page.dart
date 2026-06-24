import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/verify_email_controller.dart';

class VerifyEmailPage extends StatelessWidget {
  final String email;
  const VerifyEmailPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VerifyEmailController(),
      child: Consumer<VerifyEmailController>(
        builder: (context, controller, _) {
          return Scaffold(
  appBar: AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
    ),
  ),
  // ← add this so scaffold resizes when keyboard opens
  resizeToAvoidBottomInset: true,
  body: SingleChildScrollView(
    padding: const EdgeInsets.all(24.0),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height -
            AppBar().preferredSize.height -
            MediaQuery.of(context).padding.top,
      ),
      child: IntrinsicHeight(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.email_outlined,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Verify your Email',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'We sent a 6-digit code to $email. Enter it below to verify your account.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
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
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (controller.errorMessage != null)
              Text(
                controller.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            if (controller.successMessage != null)
              Text(
                controller.successMessage!,
                style: const TextStyle(color: Colors.green),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading
                    ? null
                    : () => controller.verifyEmail(context, email),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: controller.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Verify',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Didn't receive the code? ",
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: controller.isResending
                      ? null
                      : () => controller.resendVerification(email),
                  child: controller.isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Resend',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
        },
      ),
    );
  }
}