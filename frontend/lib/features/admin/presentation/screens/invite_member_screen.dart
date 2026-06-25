import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';
import '../../domain/gym_model.dart';

class InviteMemberScreen extends StatefulWidget {
  final GymModel gym;
  final String token;

  const InviteMemberScreen({
    super.key,
    required this.gym,
    required this.token,
  });

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _monthsController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _priceError;
  String _inviteAs = 'client';
  String _subscriptionType = 'monthly';

  bool get _isCoach => _inviteAs == 'coach';

  String get _subscriptionSummary {
    final months = int.tryParse(_monthsController.text) ?? 1;
    if (_subscriptionType == 'yearly') {
      return '$months year${months > 1 ? 's' : ''} subscription';
    }
    return '$months month${months > 1 ? 's' : ''} subscription';
  }

  Future<void> _send() async {
  final email = _emailController.text.trim();
  
  setState(() {
    _error = null;
    _priceError = null;
  });

  if (email.isEmpty) {
    setState(() => _error = 'Please enter an email address');
    return;
  }

  if (!_isCoach) {
    final price = int.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      setState(() => _priceError = 'Please enter a valid subscription price');
      return;
    }
  }

  setState(() {
    _loading = true;
  });

  try {
    if (_isCoach) {
      await AdminApiService.inviteCoach(
          widget.gym.gymID, email, widget.token);
    } else {
      await AdminApiService.inviteClient(
        widget.gym.gymID,
        email,
        widget.token,
        subscriptionType: _subscriptionType,      
        subscriptionMonths: int.tryParse(_monthsController.text) ?? 1, 
        subscriptionPrice: int.tryParse(_priceController.text) ?? 0,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation sent successfully')),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF6C63FF);

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add, color: accentColor),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invite to Titan Fitness Downtown',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          'Enter details to send a membership invitation',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Invite As Dropdown
              const Text('Invite as *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _inviteAs,
                    isExpanded: true,
                    onChanged: (v) => setState(() => _inviteAs = v!),
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
              ),
              const SizedBox(height: 16),

              // Email Field
              const Text('Email Address *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'email@example.com',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _error,
                ),
              ),

              // Subscription Details — hidden for coach
              if (!_isCoach) ...[
                const SizedBox(height: 24),

                // Subscription Details Section Header
                Row(
                  children: const [
                    Icon(Icons.calendar_month, color: accentColor, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Subscription Details',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: accentColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Subscription Type Toggle
                const Text('Subscription Type *',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _subscriptionType = 'monthly'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _subscriptionType == 'monthly'
                                ? Colors.white
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _subscriptionType == 'monthly'
                                  ? accentColor
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Monthly',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _subscriptionType == 'monthly'
                                  ? accentColor
                                  : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _subscriptionType = 'yearly'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _subscriptionType == 'yearly'
                                ? Colors.white
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _subscriptionType == 'yearly'
                                  ? accentColor
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Yearly',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _subscriptionType == 'yearly'
                                  ? accentColor
                                  : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Number of Months/Years
                Text(
                  _subscriptionType == 'yearly'
                      ? 'Number of Years *'
                      : 'Number of Months *',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _monthsController,
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
                const SizedBox(height: 16),
                const Text('Subscription Price *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'e.g. 50',
                    prefixText: '\$ ',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),borderSide: BorderSide.none,),
                    errorText: _priceError,   
                  ),
                ),
                
                const SizedBox(height: 12),

                // Summary Chip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _subscriptionSummary,
                    style: const TextStyle(
                        color: accentColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
              

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
                      onPressed: _loading ? null : _send,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, size: 16),
                      label:
                          Text(_loading ? 'Sending...' : 'Send Invitation'),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}