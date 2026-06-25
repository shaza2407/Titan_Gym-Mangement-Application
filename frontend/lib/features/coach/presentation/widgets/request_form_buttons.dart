import 'package:flutter/material.dart';
import '../controllers/coach_schedule_controller.dart';

class RequestFormButtons extends StatelessWidget {
  final CoachScheduleController ctrl;
  final String token;

  const RequestFormButtons({super.key, required this.ctrl, required this.token});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (ctrl.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(ctrl.errorMessage!, style: const TextStyle(color: Colors.red)),
          ),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: ctrl.isSubmitting
                ? null
                : () async {
                    final success = await ctrl.submitRequest(token);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request submitted successfully!'),
                          backgroundColor: Color(0xFF4CAF50),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: ctrl.isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Submit Request', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }
}