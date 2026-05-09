import 'package:flutter/material.dart';


class MyClassesListView extends StatelessWidget {
  final int coachId;
  const MyClassesListView({super.key, required this.coachId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Classes I Teach", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text("Your current class offerings", style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),
        
        // Example Card
        _buildOfferingCard("Morning Cardio Blast", "Titan Downtown", "Mon, Wed, Fri - 7:00 AM", "12/20"),
        _buildOfferingCard("Strength & Conditioning", "Titan Uptown", "Tue, Thu - 6:00 PM", "18/20"),
      ],
    );
  }

  Widget _buildOfferingCard(String title, String gym, String time, String capacity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(gym, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Text(capacity, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
    );
  }
}