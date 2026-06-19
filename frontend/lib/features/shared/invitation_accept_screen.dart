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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation declined.')),
        );
        Navigator.pop(context, false); // return false = declined
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
                  const Text(
                    'You have been invited to join this gym as a client member.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Accept Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _accept,
                      icon: const Icon(Icons.check_circle_outline,
                          color: Colors.white),
                      label: const Text('Accept Invitation',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
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
                      icon: const Icon(Icons.cancel_outlined,
                          color: Colors.red),
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