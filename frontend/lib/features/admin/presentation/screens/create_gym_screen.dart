//done
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/create_gym_controller.dart';

class CreateGymScreen extends StatelessWidget {
  final String token;

  const CreateGymScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateGymController(),
      child: const _CreateGymView(),
    );
  }
}

class _CreateGymView extends StatelessWidget {
  const _CreateGymView();

  @override
  Widget build(BuildContext context) {
    final token = context.findAncestorWidgetOfExactType<CreateGymScreen>()!.token;

    return Consumer<CreateGymController>(
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Create New Gym',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Add a new location to your network',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Basic Info ──────────────────────────────────────────────
                _sectionHeader(
                    Icons.article, 'Basic Information', 'Enter the gym details'),
                const SizedBox(height: 12),
                _formField(controller.gymNameController, 'Gym Name *',
                    hint: 'e.g., Titan Fitness Central'),
                _formField(controller.locationController, 'Location *',
                    hint: 'e.g., 123 Main St, Cairo'),

                const SizedBox(height: 16),

                // ── Schedule ────────────────────────────────────────────────
                _sectionHeader(
                    Icons.access_time, 'Schedule', 'Set operating hours'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickTime(
                            context, controller.openingHoursController),
                        child: AbsorbPointer(
                          child: _formField(
                            controller.openingHoursController,
                            'Opening Hours *',
                            hint: '06:00',
                            suffixIcon: const Icon(Icons.access_time,
                                color: Color(0xFF4F46E5)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickTime(
                            context, controller.closingHoursController),
                        child: AbsorbPointer(
                          child: _formField(
                            controller.closingHoursController,
                            'Closing Hours *',
                            hint: '23:00',
                            suffixIcon: const Icon(Icons.access_time,
                                color: Color(0xFF4F46E5)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Settings ────────────────────────────────────────────────
                _sectionHeader(
                    Icons.settings, 'Settings', 'Gym configuration'),
                const SizedBox(height: 12),
                _dropdownField(
                  label: 'Gym Type',
                  value: controller.selectedGymType,
                  items: controller.gymTypeOptions,
                  onChanged: controller.setGymType,
                ),

                const SizedBox(height: 24),

                // ── Machines ────────────────────────────────────────────────
                _sectionHeader(Icons.fitness_center, 'Gym Machines',
                    'Add available equipment'),
                const SizedBox(height: 12),

                ...List.generate(controller.machines.length, (index) {
                  final machine = controller.machines[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Machine ${index + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () =>
                                  controller.removeMachine(index),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Machine Name *',
                              hintText: 'e.g., Treadmill',
                              filled: true,
                              fillColor: const Color(0xFFEEF0F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) =>
                                controller.updateMachineName(index, val),
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF0F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: machine.machineType,
                            decoration: const InputDecoration(
                              labelText: 'Machine Type',
                              border: InputBorder.none,
                            ),
                            items: controller.machineTypeOptions
                                .map((t) => DropdownMenuItem(
                                    value: t, child: Text(t)))
                                .toList(),
                            onChanged: (val) =>
                                controller.updateMachineType(index, val!),
                          ),
                        ),
                        Row(
                          children: [
                            const Text('Quantity:',
                                style:
                                    TextStyle(fontWeight: FontWeight.w500)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: machine.quantity > 1
                                  ? () => controller.updateMachineQuantity(
                                      index, machine.quantity - 1)
                                  : null,
                            ),
                            Text('${machine.quantity}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: Color(0xFF4F46E5)),
                              onPressed: () =>
                                  controller.updateMachineQuantity(
                                      index, machine.quantity + 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                TextButton.icon(
                  onPressed: controller.addMachine,
                  icon: const Icon(Icons.add, color: Color(0xFF4F46E5)),
                  label: const Text('Add Machine',
                      style: TextStyle(color: Color(0xFF4F46E5))),
                ),

                const SizedBox(height: 16),

                // ── Error ───────────────────────────────────────────────────
                if (controller.errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Submit ──────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isCreating
                        ? null
                        : () async {
                            final success =
                                await controller.createGym(token: token);
                            if (success && context.mounted) {
                              Navigator.pop(context, controller.createdGym);
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
                        : const Text('Create Gym',
                            style: TextStyle(
                                color: Colors.white, fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
        items: items
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (v) => onChanged(v!),
      ),
    );
  }

  Future<void> _pickTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      controller.text = '$h:$m';
    }
  }
}