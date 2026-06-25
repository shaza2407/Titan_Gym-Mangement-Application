import 'package:flutter/material.dart';
import '../../domain/client_model.dart';

class ClientDetailScreen extends StatelessWidget {
  final ClientListItem member;

  const ClientDetailScreen({super.key, required this.member});

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.blue;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw;
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
            Text('Client Details',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('View client information',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(member.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              member.status,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFEDE9FF),
                  child: Icon(Icons.person, color: Color(0xFF6C63FF), size: 36),
                ),
                const SizedBox(height: 12),
                Text(member.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Client ID: #${member.id}',
                    style: const TextStyle(
                        color: Color(0xFF6C63FF), fontSize: 13)),
                const Divider(height: 28),
                _DetailRow(
                    icon: Icons.email_outlined, label: 'Email Address', value: member.email),
                const SizedBox(height: 12),
                _DetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    value: member.phone ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Subscription Card
          if (member.status != 'pending')
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.credit_card, color: Color(0xFF6C63FF)),
                      SizedBox(width: 8),
                      Text('Subscription Details',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _SubCell(
                          label: 'Plan Type',
                          value: member.subscription ?? '—'),
                      _SubCell(
                          label: 'End Date',
                          value: member.subscriptionEnd != null
                              ? _formatDate(member.subscriptionEnd!)
                              : '—'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _SubCell(
                          label: 'Join Date',
                          value: member.joined != null
                              ? _formatDate(member.joined!)
                              : '—'),
                      _SubCell(
                          label: 'Total Visits',
                          value: '${member.visits ?? 0}'),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

class _SubCell extends StatelessWidget {
  final String label, value;
  const _SubCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}