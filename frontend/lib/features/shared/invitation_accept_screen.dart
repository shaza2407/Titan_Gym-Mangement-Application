import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class InvitationScreen extends StatefulWidget {
  final int gymId;
  final String inviteToken;
  final String gymName;
  final String authToken;
  final String role;

  const InvitationScreen({
    super.key,
    required this.gymId,
    required this.inviteToken,
    required this.gymName,
    required this.authToken,
    required this.role,
  });

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  bool _loading = false;
  static const accentColor = Color(0xFF6C63FF);

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      // Step 1: check if accepting will suspend another active membership
      if (widget.role != 'coach') {
        final previewRes = await http.get(
          Uri.parse(
              '${ApiConstants.baseUrl}/admin/gyms/${widget.gymId}/invitations/preview?token=${widget.inviteToken}'),
          headers: {'Authorization': 'Bearer ${widget.authToken}'},
        );

        if (previewRes.statusCode == 200) {
          final data = jsonDecode(previewRes.body);
          final willSuspend = data['will_suspend_other_memberships'] as bool;
          final otherGyms = (data['other_active_gyms'] as List).join(', ');

          if (willSuspend) {
            setState(() => _loading = false); // pause loading while dialog is up
            if (!mounted) return;

            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Switch Gym Membership?'),
                content: Text(
                  'You currently have an active membership at $otherGyms. '
                  'Accepting this invitation will suspend it. Continue?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: accentColor),
                    child: const Text('Continue',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );

            if (confirmed != true) return; // user cancelled
            setState(() => _loading = true); // resume loading
          }
        }
      }

      // Step 2: proceed with actual acceptance
      final url = widget.role == 'coach'
          ? '${ApiConstants.baseUrl}/admin/gyms/${widget.gymId}/coaches/invitations/accept?token=${widget.inviteToken}'
          : '${ApiConstants.baseUrl}/admin/gyms/${widget.gymId}/invitations/accept?token=${widget.inviteToken}';

      final res = await http.post(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have joined the gym!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // return true = accepted
        }
      } else {
        throw Exception(jsonDecode(res.body)['detail'] ?? 'Failed');
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

  Future<void> _decline() async {
    setState(() => _loading = true);
    try {
      final url = widget.role == 'coach'
          ? '${ApiConstants.baseUrl}/admin/gyms/${widget.gymId}/coaches/invitations/decline?token=${widget.inviteToken}'
          : '${ApiConstants.baseUrl}/admin/gyms/${widget.gymId}/invitations/decline?token=${widget.inviteToken}';

      final res = await http.post(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invitation declined.')),
          );
          Navigator.pop(context, false); // return false = declined
        }
      } else {
        throw Exception(jsonDecode(res.body)['detail'] ?? 'Failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
            Text('Gym Invitation',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text('You have a new invitation',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fitness_center,
                        color: accentColor, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.gymName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.role == 'coach'
                        ? 'You have been invited to join this gym as a coach.'
                        : 'You have been invited to join this gym as a client member.',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Accept Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _accept,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline,
                              color: Colors.white),
                      label: Text(
                        _loading ? 'Please wait...' : 'Accept Invitation',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Decline Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _decline,
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      label: const Text('Decline',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}