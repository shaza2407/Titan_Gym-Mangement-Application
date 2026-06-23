import 'package:flutter/material.dart';

enum SubscriptionBlockReason { suspended, expired }

class SubscriptionBlockedScreen extends StatelessWidget {
  final SubscriptionBlockReason reason;
  final VoidCallback onBack;
  final String? gymName;

  const SubscriptionBlockedScreen({
    super.key,
    required this.reason,
    required this.onBack,
    this.gymName,
  });

  bool get _isSuspended => reason == SubscriptionBlockReason.suspended;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = _isSuspended ? Colors.red : Colors.amber.shade700;
    final Color bgColor = _isSuspended ? Colors.red.shade50 : Colors.amber.shade50;
    final IconData icon = _isSuspended ? Icons.block : Icons.event_busy;
    final String title = _isSuspended ? 'Access Suspended' : 'Subscription Expired';
    final String message = _isSuspended
        ? 'Your membership${gymName != null ? ' at $gymName' : ''} has been suspended. Please contact your gym to restore access.'
        : 'Your subscription${gymName != null ? ' at $gymName' : ''} has expired. Please contact your gym to renew and continue using this feature.';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: onBack,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: accentColor, size: 48),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: onBack,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Back to Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}