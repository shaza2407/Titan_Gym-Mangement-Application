import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/coach_profile_controller.dart';
import '../../../shared/logout_button.dart';

// --- Import widgets ---
import '../widgets/profile_avatar_card.dart';
import '../widgets/profile_section_card.dart';
import '../widgets/profile_input_fields.dart';
import '../widgets/specializations_selector.dart';
import '../widgets/save_profile_button.dart';

class CoachProfileScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onBack;
  final CoachProfileController controller;

  const CoachProfileScreen({
    super.key,
    required this.token,
    required this.controller,
    this.onBack,
  });

  @override
  State<CoachProfileScreen> createState() => CoachProfileScreenState();
}

class CoachProfileScreenState extends State<CoachProfileScreen> {
  late CoachProfileController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller;
  }

  @override
  void dispose() {
    // dashboard owns and disposes this controller
    super.dispose();
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
          if (ctrl.profile == null) {
            return Scaffold(
              backgroundColor: const Color(0xFFF5F5F5),
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    if (widget.onBack != null) widget.onBack!();
                  },
                ),
                title: const Text(
                  'Coach Profile',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ctrl.errorMessage ?? 'Unable to load your profile.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ctrl.loadProfile(widget.token),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Coach Profile',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Manage your account details',
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
                  ProfileAvatarCard(ctrl: ctrl),
                  const SizedBox(height: 16),

                  ProfileSectionCard(
                    icon: Icons.person_outline,
                    iconColor: const Color.fromARGB(255, 206, 132, 28),
                    title: 'Basic Information',
                    subtitle: 'Your personal details',
                    children: [
                      ProfileTextField(
                        label: 'Full Name',
                        controller: ctrl.nameController,
                      ),
                      ProfileReadOnlyField(
                        label: 'Email Address',
                        value: ctrl.profile?.email ?? '',
                      ),
                      ProfileTextField(
                        label: 'Phone Number',
                        controller: ctrl.phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      ProfileTextField(
                        label: 'Years of Experience',
                        controller: ctrl.yearsExperienceController,
                        keyboardType: TextInputType.number,
                      ),
                      ProfileDatePicker(ctrl: ctrl),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ProfileSectionCard(
                    icon: Icons.info_outline,
                    iconColor: const Color.fromARGB(255, 206, 132, 28),
                    title: 'About Me',
                    subtitle: 'Tell us about yourself',
                    children: [
                      ProfileTextField(
                        label: 'Bio',
                        controller: ctrl.bioController,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ProfileSectionCard(
                    icon: Icons.workspace_premium_outlined,
                    iconColor: const Color.fromARGB(255, 206, 132, 28),
                    title: 'Professional Information',
                    subtitle: 'Your coaching credentials',
                    children: [
                      ProfileTextField(
                        label: 'Certifications',
                        controller: ctrl.certificationsController,
                        hint: 'e.g. NASM-CPT, ACE',
                      ),
                      const SizedBox(height: 4),
                      SpecializationsSelector(ctrl: ctrl),
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

                  SaveProfileButton(ctrl: ctrl, token: widget.token),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
