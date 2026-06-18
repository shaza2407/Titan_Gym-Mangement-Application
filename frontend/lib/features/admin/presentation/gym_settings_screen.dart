import 'package:flutter/material.dart';
import '../data/gym_repository.dart';
import '../data/admin_repository.dart';

class GymSettingsScreen extends StatefulWidget {
  final GymModel gym;
  final String token;

  const GymSettingsScreen({
    super.key,
    required this.gym,
    required this.token,
  });

  @override
  State<GymSettingsScreen> createState() => _GymSettingsScreenState();
}

class _GymSettingsScreenState extends State<GymSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _saved = false;

  // Basic Info
  late final TextEditingController _gymNameCtrl;
  late final TextEditingController _gymTypeCtrl;

  // Location
  late final TextEditingController _locationCtrl;

  // Contact
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _websiteCtrl;

  // Hours
  late final TextEditingController _openingCtrl;
  late final TextEditingController _closingCtrl;

  // Pricing
  late final TextEditingController _monthlyCtrl;
  late final TextEditingController _yearlyCtrl;

  static const _accent = Color(0xFF4F46E5);

  @override
  void initState() {
    super.initState();
    final g = widget.gym;
    _gymNameCtrl = TextEditingController(text: g.gymName);
    _gymTypeCtrl = TextEditingController(text: g.gymType);
    _locationCtrl = TextEditingController(text: g.location);
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _websiteCtrl = TextEditingController();
    _openingCtrl = TextEditingController(text: g.openingHours);
    _closingCtrl = TextEditingController(text: g.closingHours);
    _monthlyCtrl =
        TextEditingController(text: g.subscriptionPrice.toStringAsFixed(0));
    _yearlyCtrl = TextEditingController(
        text: g.yearlySubscriptionPrice?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _gymNameCtrl.dispose();
    _gymTypeCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _openingCtrl.dispose();
    _closingCtrl.dispose();
    _monthlyCtrl.dispose();
    _yearlyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await AdminApiService.updateGym(
        gymId: widget.gym.gymID,
        token: widget.token,
        gymName: _gymNameCtrl.text.trim(),
        gymType: _gymTypeCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        openingHours: _openingCtrl.text.trim(),
        closingHours: _closingCtrl.text.trim(),
        subscriptionPrice: double.tryParse(_monthlyCtrl.text) ?? 0,
        yearlySubscriptionPrice: double.tryParse(_yearlyCtrl.text),
      );

      setState(() => _saved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gym settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // ── Basic Information ─────────────────────────────────
            _buildSection(
              icon: Icons.business_outlined,
              title: 'Basic Information',
              subtitle: 'Update gym details and branding',
              children: [
                _buildField(
                  label: 'Gym Name',
                  controller: _gymNameCtrl,
                  hint: 'e.g. Titan Fitness Center',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  label: 'Gym Type',
                  value: _gymTypeCtrl.text.isEmpty ? 'mixed' : _gymTypeCtrl.text,
                  items: const ['males', 'females', 'mixed'],
                  onChanged: (v) => setState(() => _gymTypeCtrl.text = v ?? ''),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Location ──────────────────────────────────────────
            _buildSection(
              icon: Icons.location_on_outlined,
              title: 'Location',
              subtitle: 'Gym address details',
              children: [
                _buildField(
                  label: 'Street Address',
                  controller: _locationCtrl,
                  hint: 'e.g. 123 Fitness Street, Downtown',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Contact Information ───────────────────────────────
            _buildSection(
              icon: Icons.contact_phone_outlined,
              title: 'Contact Information',
              subtitle: 'How members can reach you',
              children: [
                _buildField(
                  label: 'Phone Number',
                  controller: _phoneCtrl,
                  hint: 'e.g. +1 (555) 000-0000',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildField(
                  label: 'Email Address',
                  controller: _emailCtrl,
                  hint: 'e.g. gym@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Operating Hours ───────────────────────────────────
            _buildSection(
              icon: Icons.access_time_outlined,
              title: 'Operating Hours',
              subtitle: 'Set gym opening hours',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeField(
                        label: 'Opening Time',
                        controller: _openingCtrl,
                        hint: '06:00 AM',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeField(
                        label: 'Closing Time',
                        controller: _closingCtrl,
                        hint: '10:00 PM',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Subscription Pricing ──────────────────────────────
            _buildSection(
              icon: Icons.attach_money_outlined,
              title: 'Subscription Pricing',
              subtitle: 'Set membership fees',
              children: [
                _buildPricingCard(
                  icon: Icons.calendar_today_outlined,
                  color: _accent,
                  label: 'Monthly Subscription',
                  sublabel: 'Price per month',
                  controller: _monthlyCtrl,
                  hint: '0.00',
                ),
                const SizedBox(height: 12),
                _buildPricingCard(
                  icon: Icons.calendar_month_outlined,
                  color: const Color(0xFF1D9E75),
                  label: 'Annual Subscription',
                  sublabel: 'Price per year',
                  controller: _yearlyCtrl,
                  hint: '0.00',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Save Button ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Section Wrapper ───────────────────────────────────────────────────────
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
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _accent, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
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
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // ── Text Field ────────────────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
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
          maxLines: maxLines,
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

  // ── Dropdown Field ────────────────────────────────────────────────────────
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
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
              onChanged: onChanged,
              items: items
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                            e[0].toUpperCase() + e.substring(1)),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ── Time Field ────────────────────────────────────────────────────────────
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
            );
            if (picked != null) {
              final h = picked.hourOfPeriod.toString().padLeft(2, '0');
              final m = picked.minute.toString().padLeft(2, '0');
              final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
              controller.text = '$h:$m $period';
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

  // ── Pricing Card ──────────────────────────────────────────────────────────
  Widget _buildPricingCard({
    required IconData icon,
    required Color color,
    required String label,
    required String sublabel,
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(sublabel,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: hint,
                prefixText: '\$ ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}