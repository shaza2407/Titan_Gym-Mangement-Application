import 'package:flutter/material.dart';
import 'package:frontend/features/coach/shared/data/coach_api_service.dart';

class MyClassesListView extends StatelessWidget {
  final int coachId;
  const MyClassesListView({super.key, required this.coachId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MyClassOffering>>(
      future: CoachApiService.fetchMyClasses(coachId),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } 
        // Error state
        else if (snapshot.hasError) {
          return Center(child: Text("Error loading classes: ${snapshot.error}"));
        } 
        // Empty state
        else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("You aren't teaching any classes yet."));
        }

        final classes = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: classes.length + 1, // +1 for the text header at the top
          itemBuilder: (context, index) {
            // Render the header for the very first item
            if (index == 0) {
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Classes I Teach", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Your current class offerings", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  SizedBox(height: 16),
                ],
              );
            }

            // Render the cards for the rest
            final offering = classes[index - 1];
            return _buildOfferingCard(
              title: offering.title,
              // gym: "Gym #${offering.gymId}", // Will update when gyms are joined in DB
              time: offering.scheduleSummary,
              capacity: "${offering.currentStudents}/${offering.maxStudents}",
            );
          },
        );
      },
    );
  }

  Widget _buildOfferingCard({required String title, required String time, required String capacity}) {
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
              // Text(gym, style: const TextStyle(color: Colors.grey, fontSize: 13)),
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