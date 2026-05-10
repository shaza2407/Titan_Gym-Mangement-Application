import 'package:flutter/material.dart';
import 'package:frontend/features/coach/shared/data/coach_api_service.dart';


class RequestsListView extends StatelessWidget {
  final int coachId;
  const RequestsListView({super.key, required this.coachId});

  // --- Quick Date Formatters to match Figma ---
  String _formatProposedTime(String dateStr, String timeStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      // Simple weekday formatting
      List<String> weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
      String weekday = weekdays[date.weekday - 1];
      
      // Basic 12-hour time formatting
      int hour = int.parse(timeStr.split(':')[0]);
      String minute = timeStr.split(':')[1];
      String ampm = hour >= 12 ? "PM" : "AM";
      hour = hour % 12;
      hour = hour == 0 ? 12 : hour;
      
      return "$weekday, $hour:$minute $ampm";
    } catch (e) {
      return "$dateStr $timeStr"; // Fallback if parsing fails
    }
  }

  String _formatSubmittedDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (e) {
      return dateStr; // Fallback
    }
  }
  // -------------------------------------------

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ClassRequestHistory>>(
      future: CoachApiService.fetchRequestHistory(coachId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No request history found."));
        }

        final requests = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Request History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Your submitted class requests", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  SizedBox(height: 16),
                ],
              );
            }

            final request = requests[index - 1];
            return _buildRequestHistoryCard(
              type: request.actionType,
              status: request.status,
              className: request.className, // Using the fixed variable name!
              gym: "Titan Downtown", // Hardcoded for now to match UI
              proposed: _formatProposedTime(request.requestedDate, request.requestedTime),
              reason: request.reason,
              date: _formatSubmittedDate(request.createdAt),
            );
          },
        );
      },
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
    // Exact colors from your design
    Color statusColor = status.toLowerCase() == "approved" ? const Color(0xFF16A34A) : Colors.deepOrange;
    // Adding logic to style the Action Badge border based on type (optional but nice)
    Color typeColor = Colors.grey.shade300;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 1. Action Type Badge (Add Class / Modify Class)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: typeColor), 
                  borderRadius: BorderRadius.circular(20) 
                ),
                child: Text(type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
              const SizedBox(width: 8),
              
              // 2. Status Badge (pending / approved)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor, 
                  borderRadius: BorderRadius.circular(20) 
                ),
                child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Class Name and Location
          Text(className, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
          const SizedBox(height: 4),
          Text(gym, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          
          const SizedBox(height: 12),
          
          // Proposed Details
          Text.rich(TextSpan(children: [
            const TextSpan(text: "Proposed: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            TextSpan(text: proposed, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ])),
          
          const SizedBox(height: 4),
          
          // Reason Details
          Text.rich(TextSpan(children: [
            const TextSpan(text: "Reason: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            TextSpan(text: reason, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ])),
          
          const SizedBox(height: 12),
          
          // Submitted Date
          Text("Submitted: $date", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }
}