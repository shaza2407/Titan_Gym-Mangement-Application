import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/coach_profile_controller.dart';

class CoachProfileScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onBack;
  const CoachProfileScreen({super.key, required this.token, this.onBack});

  @override
  State<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  late CoachProfileController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = CoachProfileController();
    _ctrl.loadProfile(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<CoachProfileController>(
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
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  if (widget.onBack != null) widget.onBack!();
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
                  // ── Avatar ─────────────────────────────────────────
                  _buildAvatarCard(ctrl),
                  const SizedBox(height: 16),

                  // ── Basic Information ───────────────────────────────
                  _buildSection(
                    icon: Icons.person_outline,
                    iconColor: Color.fromARGB(255, 206, 132, 28),
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
                        'Years of Experience',
                        ctrl.yearsExperienceController,
                        keyboardType: TextInputType.number,
                      ),
                      _buildDatePicker(ctrl),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── About Me ───────────────────────────────────────
                  _buildSection(
                    icon: Icons.info_outline,
                    iconColor: const Color.fromARGB(255, 206, 132, 28),
                    title: 'About Me',
                    subtitle: 'Tell us about yourself',
                    children: [
                      _buildField('Bio', ctrl.bioController, maxLines: 3),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Professional Information ────────────────────────
                  _buildSection(
                    icon: Icons.workspace_premium_outlined,
                    iconColor: Color.fromARGB(255, 206, 132, 28),
                    title: 'Professional Information',
                    subtitle: 'Your coaching credentials',
                    children: [
                      _buildField(
                        'Certifications',
                        ctrl.certificationsController,
                        hint: 'e.g. NASM-CPT, ACE',
                      ),
                      const SizedBox(height: 4),
                      _buildSpecializations(ctrl),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (ctrl.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        ctrl.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  // ── Save Button ─────────────────────────────────────
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

  Widget _buildAvatarCard(CoachProfileController ctrl) {
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
          CircleAvatar(
            radius: 44,
            backgroundColor: Color.fromARGB(255, 206, 132, 28),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text('Coach', style: TextStyle(color: Colors.grey)),
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

  Widget _buildDatePicker(CoachProfileController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Birth',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: ctrl.dateOfBirth != null
                  ? DateTime.parse(ctrl.dateOfBirth!)
                  : DateTime(1990),
              firstDate: DateTime(1940),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              ctrl.setDateOfBirth(
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
              );
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ctrl.dateOfBirth ?? 'Select date of birth',
                  style: TextStyle(
                    color: ctrl.dateOfBirth != null
                        ? Colors.black
                        : Colors.grey,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSpecializations(CoachProfileController ctrl) {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color.fromARGB(255, 206, 132, 28)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Color.fromARGB(255, 206, 132, 28)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  spec,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
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
