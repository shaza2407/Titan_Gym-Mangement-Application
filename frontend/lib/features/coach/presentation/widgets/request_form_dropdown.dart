import 'package:flutter/material.dart';
import '../../domain/coach_schedule_model.dart'; // Adjust path if needed
import '../controllers/coach_schedule_controller.dart';

class RequestFormDropdown extends StatelessWidget {
  final CoachScheduleController ctrl;

  const RequestFormDropdown({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gym Location *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        ctrl.isLoadingGyms
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : DropdownButtonFormField<int>(
                initialValue: ctrl.selectedGymId,
                hint: const Text('Select gym location'),
                items: ctrl.gyms.map((CoachGymLookupModel gym) {
                  return DropdownMenuItem<int>(
                    value: gym.isActive? gym.id : null,
                    enabled: gym.isActive, // Disable the item if the gym is suspended
                    child:Row(
                      children: [
                        Text(
                          gym.name,
                          style: TextStyle(
                            color: gym.isActive
                                ? null                          // default theme color
                                : Theme.of(context).disabledColor,
                          ),
                        ),
                        if (!gym.isActive) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(suspended)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  ctrl.selectGym(val);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
        const SizedBox(height: 16),
      ],
    );
  }
}