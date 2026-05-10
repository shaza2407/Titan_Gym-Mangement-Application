import 'package:flutter/material.dart';
import 'package:frontend/features/coach/shared/data/coach_api_service.dart';

class ScheduleDayCard extends StatelessWidget {
  final String dayName;
  final List<ClassSessionModel> classes;

  const ScheduleDayCard({
    super.key,
    required this.dayName,
    required this.classes, 
  });

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
          // ← REPLACE hardcoded items with real data
          ...classes.map((cls) => Column(
            children: [
              _buildScheduleItem(cls.title, cls.startTime, "Gym", "${cls.currentClients}/${cls.maxStudents}"),
              if (cls != classes.last) const SizedBox(height: 12),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String title, String time, String location, String capacity) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
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
        ),
      ],
    );
  }
}