import 'package:flutter/material.dart';

class RequestsListView extends StatelessWidget {
  final int coachId;
  const RequestsListView({super.key, required this.coachId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Request History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text("Your submitted class requests", style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),
        
        _buildRequestHistoryCard(
          type: "Add Class",
          status: "pending",
          className: "Advanced HIIT",
          gym: "Titan Downtown",
          proposed: "Thursday, 6:00 PM",
          reason: "High demand from current clients",
          date: "Mar 8, 2026"
        ),
        _buildRequestHistoryCard(
          type: "Modify Class",
          status: "approved",
          className: "Morning Cardio Blast",
          gym: "Titan Downtown",
          proposed: "Monday, 7:30 AM (from 7:00 AM)",
          reason: "Better fits my schedule",
          date: "Mar 5, 2026"
        ),
      ],
    );
  }

  Widget _buildRequestHistoryCard({
    required String type,
    required String status,
    required String className,
    required String gym,
    required String proposed,
    required String reason,
    required String date,
  }) {
    Color statusColor = status == "approved" ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Type Badge (e.g., Add Class)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
                child: Text(type, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(6)),
                child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(className, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(gym, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Text.rich(TextSpan(children: [
            const TextSpan(text: "Proposed: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            TextSpan(text: proposed, style: const TextStyle(fontSize: 13)),
          ])),
          Text.rich(TextSpan(children: [
            const TextSpan(text: "Reason: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            TextSpan(text: reason, style: const TextStyle(fontSize: 13)),
          ])),
          const SizedBox(height: 8),
          Text("Submitted: $date", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }
}