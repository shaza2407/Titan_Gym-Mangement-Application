import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/coach_schedule_controller.dart';
import '../../domain/coach_schedule_model.dart';

class RequestClassScreen extends StatefulWidget {
  final String token;
  final CoachScheduleController controller;

  const RequestClassScreen({super.key, required this.token, required this.controller});

  @override
  State<RequestClassScreen> createState() => _RequestClassScreenState();
}

class _RequestClassScreenState extends State<RequestClassScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadGyms(widget.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.controller,
      child: Consumer<CoachScheduleController>(
        builder: (context, c, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request New Class', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Submit a request to the gym admin', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _formField('Class Name *', c.classNameController, 'e.g., Morning Yoga'),

                    const Text('Gym Location *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    
                    c.isLoadingGyms 
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ))
                      : DropdownButtonFormField<int>(
                          value: c.selectedGymId, 
                          hint: const Text('Select gym location'),
                          items: c.gyms.map((CoachGymLookupModel gym) {
                            return DropdownMenuItem<int>(
                              value: gym.id,
                              child: Text(gym.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            c.selectGym(val); 
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recurring (weekly)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Switch(value: c.isRecurring, onChanged: c.setRecurring, activeColor: const Color(0xFF4F46E5)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    const Text('Start Date *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          c.setDate('${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c.selectedDate ?? 'Pick a date', style: TextStyle(color: c.selectedDate != null ? Colors.black : Colors.grey)),
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Time *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) {
                          c.setTime('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00');
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c.selectedTime != null ? _formatTime(c.selectedTime!) : 'Pick a time', style: TextStyle(color: c.selectedTime != null ? Colors.black : Colors.grey)),
                            const Icon(Icons.access_time, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: _formField('Duration (min)', c.durationController, '45', keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _formField('Max Capacity *', c.maxCapacityController, '20', keyboardType: TextInputType.number)),
                      ],
                    ),

                    _formField('Reason (Optional)', c.reasonController, 'Why is this class needed?', maxLines: 3),

                    if (c.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(c.errorMessage!, style: const TextStyle(color: Colors.red)),
                      ),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: c.isSubmitting
                            ? null
                            : () async {
                                final success = await c.submitRequest(widget.token);
                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Request submitted successfully!'), backgroundColor: Color(0xFF4CAF50)),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: c.isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Submit Request', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _formField(String label, TextEditingController controller, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final min = parts[1];
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    return '${h.toString().padLeft(2, '0')}:$min $period';
  }
}

