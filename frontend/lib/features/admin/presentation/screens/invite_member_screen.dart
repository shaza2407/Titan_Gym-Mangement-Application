import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/gym_model.dart';
import '../../../shared/connectivity_helper.dart';
import '../controller/invite_member_controller.dart';

class InviteMemberScreen extends StatelessWidget {
  final GymModel gym;
  final String token;

  const InviteMemberScreen({
    super.key,
    required this.gym,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InviteMemberController(gym: gym, token: token),
      child: const _InviteMemberView(),
    );
  }
}

class _InviteMemberView extends StatelessWidget {
  const _InviteMemberView();

  static const _accent = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InviteMemberController>();

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invite Member',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text('Send a gym invitation via email',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(controller),
              const SizedBox(height: 24),

              // Invite As
              _buildLabel('Invite as *'),
              const SizedBox(height: 8),
              _buildInviteAsDropdown(controller),
              const SizedBox(height: 16),

              // Email
              _buildLabel('Email Address *'),
              const SizedBox(height: 8),
              TextField(
                controller: controller.emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'email@example.com',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  errorText: controller.errorMessage,
                ),
              ),

              // Subscription (client only)
              if (!controller.isCoach) ...[
                const SizedBox(height: 24),
                _buildSubscriptionSection(context, controller),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              _buildActions(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  // Header
  Widget _buildHeader(InviteMemberController controller) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.person_add, color: _accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.gym.gymName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Text(
                'Enter details to send a membership invitation',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Invite As Dropdown
  Widget _buildInviteAsDropdown(InviteMemberController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.inviteAs,
          isExpanded: true,
          onChanged: (v) => controller.setInviteAs(v!),
          items: const [
            DropdownMenuItem(
              value: 'client',
              child: Row(children: [
                Icon(Icons.person_outline, size: 18),
                SizedBox(width: 8),
                Text('Client (Member)'),
              ]),
            ),
            DropdownMenuItem(
              value: 'coach',
              child: Row(children: [
                Icon(Icons.sports_gymnastics, size: 18),
                SizedBox(width: 8),
                Text('Coach (Instructor)'),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // Subscription Section
  Widget _buildSubscriptionSection(
      BuildContext context, InviteMemberController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        const Row(
          children: [
            Icon(Icons.calendar_month, color: _accent, size: 18),
            SizedBox(width: 8),
            Text('Subscription Details',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _accent)),
          ],
        ),
        const SizedBox(height: 16),

        // Type toggle
        _buildLabel('Subscription Type *'),
        const SizedBox(height: 8),
        _buildSubscriptionToggle(controller),
        const SizedBox(height: 16),

        // Months / Years
        _buildLabel(controller.subscriptionType == 'yearly'
            ? 'Number of Years *'
            : 'Number of Months *'),
        const SizedBox(height: 8),
        TextField(
          controller: controller.monthsCtrl,
          keyboardType: TextInputType.number,
          onChanged: (_) => controller.notifyMonthsChanged(),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Price
        _buildLabel('Subscription Price *'),
        const SizedBox(height: 8),
        TextField(
          controller: controller.priceCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'e.g. 50',
            prefixText: '\$ ',
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            errorText: controller.priceError,
          ),
        ),
        const SizedBox(height: 12),

        // Summary chip
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            controller.subscriptionSummary,
            style: const TextStyle(
                color: _accent, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // Subscription Type Toggle
  Widget _buildSubscriptionToggle(InviteMemberController controller) {
    return Row(
      children: ['monthly', 'yearly'].map((type) {
        final isSelected = controller.subscriptionType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => controller.setSubscriptionType(type),
            child: Container(
              margin: type == 'yearly'
                  ? const EdgeInsets.only(left: 6)
                  : const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? _accent : Colors.transparent,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                type[0].toUpperCase() + type.substring(1),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _accent : Colors.black54,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Action Buttons
  Widget _buildActions(
      BuildContext context, InviteMemberController controller) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: controller.isLoading
                ? null
                : () async {
                  final online = await ConnectivityHelper.isOnline();
                  if(!online){
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('You are offline. Please try again when you\'re connected.')),
                      );
                    }
                    else{
                    final success = await controller.send();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Invitation sent successfully')),
                      );
                      Navigator.pop(context);
                    }
              }},
            icon: controller.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send, size: 16),
            label:
                Text(controller.isLoading ? 'Sending...' : 'Send Invitation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  // Shared
  Widget _buildLabel(String text) {
    return Text(text,
        style:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13));
  }
}