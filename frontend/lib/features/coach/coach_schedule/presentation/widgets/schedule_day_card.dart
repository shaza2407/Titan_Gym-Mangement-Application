import 'package:flutter/material.dart';

class ScheduleDayCard extends StatelessWidget {
  final String dayName;
  // In a real app, you'd pass a List of Class objects here. 
  // For UI testing, we'll just hardcode the internal items.

  const ScheduleDayCard({super.key, required this.dayName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Example of a single class item inside the day card
          _buildScheduleItem("Morning Cardio Blast", "07:00 AM", "Titan Downtown", "12/20"),
          const SizedBox(height: 12),
          _buildScheduleItem("Evening Yoga Flow", "07:00 PM", "Titan Downtown", "15/15"),
        ],
      ),
    );
  }

  // A private helper method just for building the rows with the purple line
  Widget _buildScheduleItem(String title, String time, String location, String capacity) {
    return Row(
      children: [
        // The vertical purple line
        Container(
          width: 3,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        // Class Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(width: 12),
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(location, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ),
        // Capacity Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            capacity,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
        )
      ],
    );
  }
}