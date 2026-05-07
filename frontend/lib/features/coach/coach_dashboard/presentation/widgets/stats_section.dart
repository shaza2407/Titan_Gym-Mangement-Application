import 'package:flutter/material.dart';

class StatItemData {
  final Icon icon;
  final String label;
  final num number;

  const StatItemData({
    required this.icon,
    required this.label,
    required this.number,
  });
}

class StatsSection extends StatelessWidget {
  final List<StatItemData> stats;

  const StatsSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    List<Widget> rowChildren = [];
    
    for (int i = 0; i < stats.length; i++) {
      rowChildren.add(
        Expanded(
          child: StatCard(
            icon: stats[i].icon,
            label: stats[i].label,
            number: stats[i].number,
          ),
        ),
      );
      
      // Add a SizedBox for spacing EXCEPT after the very last card
      if (i < stats.length - 1) {
        rowChildren.add(const SizedBox(width: 12));
      }
    }

    return Row(
      children: rowChildren,
    );
  }
}

// 3. Your existing StatCard (No changes needed here!)
class StatCard extends StatelessWidget {
  final Icon icon;
  final String label;
  final num number;
  
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 12),
          Text(
            number.toString(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}