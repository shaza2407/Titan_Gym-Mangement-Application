import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/client_profile_controller.dart';

class ClientProfileScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onBack;
  const ClientProfileScreen({super.key, required this.token, this.onBack});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  late ClientProfileController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ClientProfileController();
    _ctrl.loadProfile(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<ClientProfileController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  }
                },
              ),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Profile',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Update your personal information',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Avatar ─────────────────────────────────────
                  _buildAvatarCard(ctrl),
                  const SizedBox(height: 16),

                  // ── Basic Information ───────────────────────────
                  _buildSection(
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF4CAF50),
                    title: 'Basic Information',
                    subtitle: 'Your personal details',
                    children: [
                      _buildField('Full Name', ctrl.nameController),
                      _buildReadOnly(
                        'Email Address',
                        ctrl.profile?.email ?? '',
                      ),
                      _buildField(
                        'Phone Number',
                        ctrl.phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildField(
                        'Age',
                        ctrl.ageController,
                        keyboardType: TextInputType.number,
                      ),
                      _buildDropdown(
                        label: 'Gender',
                        value: ctrl.selectedGender,
                        items: ctrl.genders,
                        onChanged: ctrl.setGender,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Fitness Goal ────────────────────────────────
                  _buildSection(
                    icon: Icons.fitness_center,
                    iconColor: const Color(0xFF4F46E5),
                    title: 'Fitness Goal',
                    subtitle: 'What are you working towards?',
                    children: [
                      _buildDropdown(
                        label: 'Goal',
                        value: ctrl.selectedFitnessGoal,
                        items: ctrl.fitnessGoals,
                        onChanged: ctrl.setFitnessGoal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── About Me ────────────────────────────────────
                  _buildSection(
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFF4CAF50),
                    title: 'About Me',
                    subtitle: 'Tell us about yourself',
                    children: [
                      _buildField('Bio', ctrl.bioController, maxLines: 3),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Emergency Contact ───────────────────────────
                  _buildSection(
                    icon: Icons.emergency_outlined,
                    iconColor: Colors.red,
                    title: 'Emergency Contact',
                    subtitle: 'In case of emergency',
                    children: [
                      _buildField(
                        'Contact Information',
                        ctrl.emergencyContactController,
                        hint: 'Name - Phone number',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Error ───────────────────────────────────────
                  if (ctrl.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        ctrl.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  // ── Save Button ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: ctrl.isSaving
                          ? null
                          : () async {
                              final success = await ctrl.saveProfile(
                                widget.token,
                              );
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Profile updated successfully',
                                    ),
                                    backgroundColor: Color(0xFF4CAF50),
                                  ),
                                );
                              }
                            },
                      icon: ctrl.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        ctrl.isSaving ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────

  Widget _buildAvatarCard(ClientProfileController ctrl) {
    final name = ctrl.profile?.name ?? '';
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: const Color(0xFF4CAF50),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text('Client', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint ?? label,
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

  Widget _buildReadOnly(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(value, style: const TextStyle(color: Colors.black54)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text('Select $label'),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
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
