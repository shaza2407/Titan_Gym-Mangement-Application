import 'package:flutter/material.dart';
import 'package:frontend/features/coach/shared/data/coach_api_service.dart';

class UpcomingClassesSection extends StatelessWidget {
  final String token;
  const UpcomingClassesSection({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ClassSessionModel>>(
      future: CoachApiService.fetchDashboardUpcomingClasses(token),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text(
            "No upcoming classes scheduled.",
            style: TextStyle(color: Colors.grey),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Upcoming Classes",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...snapshot.data!.map((cls) => _buildClassCard(cls)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildClassCard(ClassSessionModel cls) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: Colors.purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Text("Gym #${cls.gymId}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                cls.startTime,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${cls.currentClients}/${cls.maxStudents}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// class ClassCard extends StatelessWidget {
//   final String title;
//   final String location;
//   final String time;
//   final int currentStudents;
//   final int maxStudents;

//   const ClassCard({
//     super.key,
//     required this.title,
//     required this.location,
//     required this.time,
//     required this.currentStudents,
//     required this.maxStudents,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Determine if the class is full to maybe change badge color (optional UI polish)
//     final isFull = currentStudents >= maxStudents;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade200, width: 1),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.02),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // 1. The Icon with light purple background
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: Colors.purple.shade50, // Very light purple
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Icon(
//               Icons.calendar_today_outlined,
//               color: Colors.purple,
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 16),

//           // 2. Middle Section: Title & Location (Expanded takes up remaining middle space)
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   location,
//                   style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
//                 ),
//               ],
//             ),
//           ),

//           // 3. Right Section: Time & Capacity Badge
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 time,
//                 style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 6),

//               // The Capacity Badge
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade100, // Light grey badge background
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   "$currentStudents/$maxStudents",
//                   style: TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.bold,
//                     // If it's full, you could make the text red, otherwise grey
//                     color: isFull ? Colors.red.shade400 : Colors.grey.shade700,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
