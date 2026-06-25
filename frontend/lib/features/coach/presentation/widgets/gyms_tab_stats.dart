import 'package:flutter/material.dart';
import '../../presentation/controllers/coach_gyms_controller.dart';
import 'coach_ui_utils.dart'; 

class GymsTabStats extends StatelessWidget {
  final CoachGymsController ctrl;

  const GymsTabStats({super.key, required this.ctrl});

  Widget _buildStatBox(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatBox(Icons.business, '${ctrl.myGyms.length}', 'Gyms', CoachColors.warning),
        const SizedBox(width: 12),
        _buildStatBox(Icons.people_outline, '${ctrl.totalClients}', 'Clients', const Color(0xFF3B82F6)),
        const SizedBox(width: 12),
        _buildStatBox(Icons.calendar_today_outlined, '${ctrl.totalClasses}', 'Classes', const Color(0xFF10B981)),
      ],
    );
  }
}