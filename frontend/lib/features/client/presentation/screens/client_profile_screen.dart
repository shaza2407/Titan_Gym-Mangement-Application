// lib/features/client/presentation/screens/client_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/client_profile_controller.dart';
import '../../../shared/logout_button.dart';
import '../../../auth/presentation/forget_password_page.dart';

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
              backgroundColor: Color(0xFFF3F4F6),
              body: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
            );
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF3F4F6), // Light theme background
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Settings',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Manage your account details and goals',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black),
                  onPressed: () => showLogoutDialog(context),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Avatar Card ─────────────────────────────────
                  _buildAvatarCard(ctrl),
                  const SizedBox(height: 16),

                  // ── Basic Information ───────────────────────────
                  _buildSection(
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF4F46E5),
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
                      _buildDatePicker(ctrl),
                      if (ctrl.profile?.age != null)
                        _buildReadOnly('Age', '${ctrl.profile!.age} years old'),
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
                    iconColor: const Color(0xFF6366F1),
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
                    iconColor: const Color(0xFF10B981),
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
                    iconColor: Colors.redAccent,
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

                  // ── Security ────────────────────────────────────
                  _buildSecurityCard(),
                  const SizedBox(height: 16),

                  // ── Error ───────────────────────────────────────
                  if (ctrl.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        ctrl.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
                                    backgroundColor: Color(0xFF10B981),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5), // Indigo Accent
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFF4F46E5),
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 4),
          const Text(
            'Active Member',
            style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold),
          ),
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))
        ],
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
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5)),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDatePicker(ClientProfileController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Birth',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
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
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF4F46E5),
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
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
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ctrl.dateOfBirth ?? 'Select date of birth',
                  style: TextStyle(
                    color: ctrl.dateOfBirth != null
                        ? Colors.black
                        : const Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 18, color: Color(0xFF4F46E5)),
              ],
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Security ─────────────────────────────────────────────────────────────
  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.lock_outline, color: Color(0xFF4F46E5), size: 20),
              SizedBox(width: 8),
              Text(
                'Security',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ForgotPasswordPage(isLoggedIn: true),
              ),
            ),
            child: const Text(
              'Reset password?',
              style: TextStyle(
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          hint: Text('Select $label', style: const TextStyle(color: Color(0xFF9CA3AF))),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.black))))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5)),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
