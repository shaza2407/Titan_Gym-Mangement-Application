import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/admin_gym_controller.dart';

class CreateGymScreen extends StatelessWidget {
  final String token;
  const CreateGymScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: context.read<AdminGymController>(),
      child: Consumer<AdminGymController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFEEF0F8),
            appBar: AppBar(
              backgroundColor: const Color(0xFF4F46E5),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Gym',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Add a new location to your network',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Basic Information Section
                  _sectionHeader(Icons.article, 'Basic Information', 'Enter the gym details'),
                  const SizedBox(height: 12),
                  _formField(controller.gymNameController, 'Gym Name *', hint: 'e.g., Titan Fitness Central'),
                  _formField(controller.locationController, 'Location *', hint: 'e.g., 123 Main St, Cairo'),
                  _formField(controller.priceController,'Monthly Subscription Price *',hint: 'e.g., 199.99',keyboardType: TextInputType.number),
                  _formField(controller.yearlyPriceController,'Yearly Subscription Price *',hint: 'e.g., 999.99',keyboardType: TextInputType.number),


                  const SizedBox(height: 16),

                  // operating hours Section
                  _sectionHeader(Icons.access_time, 'Schedule', 'Set operating hours'),
                  const SizedBox(height: 12),
                  Row(
                  children: [
                    Expanded(
                    child: GestureDetector(
                        onTap: () => _pickTime(context, controller.openingHoursController),
                        child: AbsorbPointer(  // prevent manual editing
                          child: _formField(
                            controller.openingHoursController,'Opening Hours *',hint: '06:00',
                            suffixIcon: const Icon(Icons.access_time, color: Color(0xFF4F46E5)),
                          ),
                        ),
                       ),
                      ),
                  const SizedBox(width: 12),
                  Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(context, controller.closingHoursController),
                    child: AbsorbPointer(
                      child: _formField(controller.closingHoursController,'Closing Hours *',hint: '23:00',suffixIcon: const Icon(Icons.access_time, color: Color(0xFF4F46E5)),
                      ),
                    ),
                  ),
                ),
                ],
                ),

                  const SizedBox(height: 16),

                  // Settings Section
                  _sectionHeader(Icons.settings, 'Settings', 'Gym configuration'),
                  const SizedBox(height: 12),


                  const SizedBox(height: 12),

                  // Gym Type dropdown
                  _dropdownField(
                    label: 'Gym Type',
                    value: controller.selectedGymType,
                    items: controller.gymTypeOptions,
                    onChanged: controller.setGymType,
                  ),

                  const SizedBox(height: 24),

                  // error message
                  if (controller.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        controller.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isCreating
                          ? null
                          : () async {
                              await controller.createGym(token: token);
                              if (controller.errorMessage == null) {
                                Navigator.pop(context); // ✅ go back on success
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isCreating
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Create Gym',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4F46E5)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formField(
    TextEditingController controller,
    String label, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) => onChanged(v!),
      ),
    );
  }
}


Future<void> _pickTime(BuildContext context, TextEditingController controller) async {
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      );
    },
  );

  if (picked != null) {
    final hours   = picked.hour.toString().padLeft(2, '0');
    final minutes = picked.minute.toString().padLeft(2, '0');
    controller.text = '$hours:$minutes'; // e.g. 06:00
  }
}