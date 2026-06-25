import 'package:flutter/material.dart';
import '../controllers/coach_profile_controller.dart';

class SaveProfileButton extends StatelessWidget {
  final CoachProfileController ctrl;
  final String token;

  const SaveProfileButton({super.key, required this.ctrl, required this.token});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: ctrl.isSaving
            ? null
            : () async {
                final success = await ctrl.saveProfile(token);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                }
              },
        icon: ctrl.isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save, color: Colors.white),
        label: Text(
          ctrl.isSaving ? 'Saving...' : 'Save Changes',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}