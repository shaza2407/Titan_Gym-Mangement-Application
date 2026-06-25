//done
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/renew_membership_controller.dart';
import '../../domain/client_model.dart';


class RenewMembershipScreen extends StatefulWidget {
  final ClientListItem member;
  final int gymId;
  final String token;

  const RenewMembershipScreen({
    super.key,
    required this.member,
    required this.gymId,
    required this.token,
  });

  @override
  State<RenewMembershipScreen> createState() => _RenewMembershipScreenState();
}

class _RenewMembershipScreenState extends State<RenewMembershipScreen> {
  late final RenewMembershipController _controller;

  static const accentColor = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _controller = RenewMembershipController();
    // rebuild when months text changes for summary
    _controller.monthsController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await _controller.renew(
      token:    widget.token,
      gymId:    widget.gymId,
      memberId: widget.member.id,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Membership renewed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Failed to renew'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<RenewMembershipController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: _buildAppBar(),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildMemberCard(),
                  const SizedBox(height: 16),
                  _buildRenewalForm(controller),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Renew Membership',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text('Extend member subscription',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMemberCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFEDE9FF),
            child: Icon(Icons.person, color: accentColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.member.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Text(widget.member.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(
                'Current: ${widget.member.subscription ?? '—'}',
                style: const TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRenewalForm(RenewMembershipController controller) {
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_month,
                    color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Renewal Details',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Set new subscription period',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Subscription Type Toggle
          const Text('Subscription Type',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeToggle(controller, 'monthly', 'Monthly'),
              const SizedBox(width: 12),
              _buildTypeToggle(controller, 'yearly', 'Yearly'),
            ],
          ),
          const SizedBox(height: 16),

          // Duration
          Text(
            controller.subscriptionType == 'yearly'
                ? 'Number of Years'
                : 'Number of Months',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.monthsController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Summary chip
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              controller.subscriptionSummary,
              style: const TextStyle(
                  color: accentColor, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),

          // Price
          const Text('Price Paid',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: controller.priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '\$ ',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
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
                  onPressed: controller.isLoading ? null : _submit,
                  icon: controller.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.restart_alt,
                          size: 16, color: Colors.white),
                  label: Text(
                    controller.isLoading ? 'Renewing...' : 'Renew',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle(
      RenewMembershipController controller, String type, String label) {
    final isSelected = controller.subscriptionType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setSubscriptionType(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? accentColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? accentColor : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}