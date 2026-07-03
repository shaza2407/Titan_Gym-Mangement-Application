import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/gym_model.dart';
import '../controller/gym_settings_controller.dart';

class GymSettingsScreen extends StatelessWidget {
  final GymModel gym;
  final String token;

  const GymSettingsScreen({
    super.key,
    required this.gym,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GymSettingsController(gym: gym, token: token),
      child: const _GymSettingsView(),
    );
  }
}

class _GymSettingsView extends StatefulWidget {
  const _GymSettingsView();

  @override
  State<_GymSettingsView> createState() => _GymSettingsViewState();
}

class _GymSettingsViewState extends State<_GymSettingsView> {
  static const _accent = Color(0xFF4F46E5);
  final _formKey = GlobalKey<FormState>();

  final List<TextEditingController> _nameControllers = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncNameControllers();
  }

  void _syncNameControllers() {
    final controller = context.read<GymSettingsController>();
    while (_nameControllers.length < controller.machines.length) {
      final index = _nameControllers.length;
      _nameControllers.add(
        TextEditingController(text: controller.machines[index].machineName),
      );
    }
    while (_nameControllers.length > controller.machines.length) {
      _nameControllers.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _confirmDeleteGym(GymSettingsController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Delete Gym',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this gym?\n\n'
          'This action is permanent and cannot be undone. '
          'All members, coaches, and data will be lost forever.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yes, Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
  if (!mounted) return;

  try {
    await controller.deleteGym();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gym deleted successfully'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context, rootNavigator: true).pop();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GymSettingsController>();
    _syncNameControllers();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Gym Settings',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text('Update gym information and settings',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // Basic Information
            _buildSection(
              icon: Icons.business_outlined,
              title: 'Basic Information',
              subtitle: 'Update gym details and branding',
              children: [
                _buildField(
                  label: 'Gym Name',
                  controller: controller.gymNameCtrl,
                  hint: 'e.g. Titan Fitness Center',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  label: 'Gym Type',
                  value: controller.selectedGymType,
                  items: const ['males', 'females', 'mixed'],
                  onChanged: controller.setGymType,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location
            _buildSection(
              icon: Icons.location_on_outlined,
              title: 'Location',
              subtitle: 'Gym address details',
              children: [
                _buildField(
                  label: 'Street Address',
                  controller: controller.locationCtrl,
                  hint: 'e.g. 123 Fitness Street, Downtown',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Operating Hours
            _buildSection(
              icon: Icons.access_time_outlined,
              title: 'Operating Hours',
              subtitle: 'Set gym opening and closing hours',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeField(
                        label: 'Opening Time',
                        controller: controller.openingCtrl,
                        hint: '06:00',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeField(
                        label: 'Closing Time',
                        controller: controller.closingCtrl,
                        hint: '23:00',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Machines
            _buildSection(
              icon: Icons.fitness_center,
              title: 'Gym Machines',
              subtitle: 'Manage your equipment list',
              children: [
                ...List.generate(controller.machines.length, (index) {
                  final machine = controller.machines[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
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
                        TextField(
                          controller: _nameControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Machine Name *',
                            hintText: 'e.g., Treadmill',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) =>
                              controller.updateMachineName(index, val),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Quantity:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                  Icons.remove_circle_outline),
                              onPressed: machine.quantity > 1
                                  ? () =>
                                      controller.updateMachineQuantity(
                                          index, machine.quantity - 1)
                                  : null,
                            ),
                            Text('${machine.quantity}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: _accent),
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
                  icon: const Icon(Icons.add, color: _accent),
                  label: const Text('Add Machine',
                      style: TextStyle(color: _accent)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Error
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
                      child: Text(controller.errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        final success = await controller.save();
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Gym settings saved successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: controller.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),

            // Delete Gym Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmDeleteGym(controller),
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('Delete Gym',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Helpers

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              onChanged: (v) => onChanged(v!),
              items: items
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child:
                            Text(e[0].toUpperCase() + e.substring(1)),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
              builder: (ctx, child) => MediaQuery(
                data: MediaQuery.of(ctx)
                    .copyWith(alwaysUse24HourFormat: true),
                child: child!,
              ),
            );
            if (picked != null) {
              final h = picked.hour.toString().padLeft(2, '0');
              final m = picked.minute.toString().padLeft(2, '0');
              controller.text = '$h:$m';
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.text.isEmpty ? hint : controller.text,
                  style: TextStyle(
                    color: controller.text.isEmpty
                        ? Colors.grey
                        : Colors.black,
                  ),
                ),
                const Icon(Icons.access_time,
                    size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}