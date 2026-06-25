import 'package:flutter/material.dart';
import '../controllers/coach_schedule_controller.dart';
import '../screens/request_class_screen.dart';

class RequestClassButton extends StatelessWidget {
  final CoachScheduleController ctrl;
  final String token;

  const RequestClassButton({super.key, required this.ctrl, required this.token});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestClassScreen(token: token, controller: ctrl),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Request New Class Time',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}