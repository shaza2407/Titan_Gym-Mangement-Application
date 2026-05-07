import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget {
  const CustomTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Selected Tab
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white, // The white "pill" indicating selection
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                ],
              ),
              child: const Center(
                child: Text("Schedule", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          // Unselected Tab 1
          const Expanded(
            child: Center(
              child: Text("My Classes", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            ),
          ),
          // Unselected Tab 2
          const Expanded(
            child: Center(
              child: Text("Requests", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}