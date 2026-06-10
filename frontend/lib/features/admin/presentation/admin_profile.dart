import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/logout_button.dart';
import '../controller/admin_profile_controller.dart';

class AdminProfileScreen extends StatefulWidget {
  final String token;
  final int gymId;
  final void Function(int)? onTabChange;

  const AdminProfileScreen({
    super.key,
    required this.token,
    required this.gymId,  
    this.onTabChange  
    });

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late AdminProfileController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AdminProfileController();
    _ctrl.loadProfile(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<AdminProfileController>(
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
              title: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Admin Profile',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Manage your account information',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              centerTitle: true,
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
                  // ── Avatar ────────────────────────────────────────
                  _buildAvatarCard(ctrl),
                  const SizedBox(height: 16),

                  // ── Personal Information ──────────────────────────
                  _buildSection(
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF4F46E5),
                    title: 'Personal Information',
                    subtitle: 'Your personal details',
                    children: [
                      _buildField('Full Name', ctrl.nameController),
                      _buildReadOnly('Email Address', ctrl.profile?.email ?? ''),
                      _buildField(
                        'Phone Number',
                        ctrl.phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Security ──────────────────────────────────────
                  _buildSection(
                    icon: Icons.lock_outline,
                    iconColor: const Color(0xFF4F46E5),
                    title: 'Security',
                    subtitle: 'Update your password',
                    children: [
                      _buildField(
                        'Current Password',
                        ctrl.currentPasswordController,
                        obscure: true,
                      ),
                      _buildField(
                        'New Password',
                        ctrl.newPasswordController,
                        obscure: true,
                      ),
                      _buildField(
                        'Confirm New Password',
                        ctrl.confirmPasswordController,
                        obscure: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Account Info ──────────────────────────────────
                  _buildSection(
                    icon: Icons.badge_outlined,
                    iconColor: const Color(0xFF1D9E75),
                    title: 'Account Info',
                    subtitle: 'Your account details',
                    children: [
                      _buildReadOnly('Role', 'Administrator'),
                      _buildReadOnly(
                        'Member Since',
                        ctrl.profile?.createdAt ?? '-',
                      ),
                      _buildReadOnly(
                        'Total Gyms Managed',
                        '${ctrl.profile?.totalGyms ?? 0} gyms',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Error ─────────────────────────────────────────
                  if (ctrl.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        ctrl.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  // ── Save Button ───────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: ctrl.isSaving
                          ? null
                          : () async {
                              final success =
                                  await ctrl.saveProfile(widget.token);
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Profile updated successfully'),
                                    backgroundColor: Color(0xFF4F46E5),
                                  ),
                                );
                              }
                            },
                      icon: ctrl.isSaving
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        ctrl.isSaving ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.white),
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

  // ── Avatar card ───────────────────────────────────────────────────────────
  Widget _buildAvatarCard(AdminProfileController ctrl) {
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
            backgroundColor: const Color(0xFF4F46E5), // ← blue for admin
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
          Text(name,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Administrator',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Admin Account',
              style: TextStyle(
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section ───────────────────────────────────────────────────────────────
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
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ── Field ─────────────────────────────────────────────────────────────────
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
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
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

  // ── Read only ─────────────────────────────────────────────────────────────
  Widget _buildReadOnly(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(value,
              style: const TextStyle(color: Colors.black54)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}