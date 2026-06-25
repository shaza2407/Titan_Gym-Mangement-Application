import 'package:flutter/material.dart';
import '../controllers/coach_profile_controller.dart';

class SpecializationsSelector extends StatelessWidget {
  final CoachProfileController ctrl;

  const SpecializationsSelector({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specializations',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select all that apply',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ctrl.availableSpecializations.map((spec) {
            final isSelected = ctrl.selectedSpecializations.contains(spec);
            return GestureDetector(
              onTap: () => ctrl.toggleSpecialization(spec),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color.fromARGB(255, 206, 132, 28) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color.fromARGB(255, 206, 132, 28) : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  spec,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}