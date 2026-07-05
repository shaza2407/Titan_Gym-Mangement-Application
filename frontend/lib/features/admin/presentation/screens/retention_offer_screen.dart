import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/retention_offer_controller.dart';
import '../../domain/retention_offer_model.dart';
import 'offer_details_screen.dart';
import 'create_offer_screen.dart';

class RetentionOfferScreen extends StatelessWidget {
  final String token;
  final int gymId;

  const RetentionOfferScreen({
    super.key,
    required this.token,
    required this.gymId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          RetentionOfferController(token: token, gymId: gymId)..loadDashboard(),
      child: Consumer<RetentionOfferController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFEEF0F8),
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
                  Text('Retention & Churn Prevention',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text('AI-powered member retention',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            body: controller.isLoadingDashboard
                ? const Center(child: CircularProgressIndicator())
                : controller.dashboardError != null
                    ? Center(
                        child: Text(controller.dashboardError!,
                            style: const TextStyle(color: Colors.red)))
                    : _buildBody(context, controller),
          );
        },
      ),
    );
  }

  // Body
  Widget _buildBody(
      BuildContext context, RetentionOfferController controller) {
    final dashboard = controller.dashboard!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stat Cards
        Row(
          children: [
            Expanded(
                child: _statCard(
                    'High Risk', '${dashboard.highRiskCount}', Colors.red)),
            const SizedBox(width: 12),
            Expanded(
                child: _statCard(
                    'Mid Risk', '${dashboard.midRiskCount}', Colors.orange)),
            const SizedBox(width: 12),
            Expanded(
                child: _statCard('Offers Sent', '${dashboard.offersSent}',
                    const Color(0xFF4F46E5))),
          ],
        ),
        const SizedBox(height: 16),

        // AI Insight
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EEFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome,
                  color: Color(0xFF4F46E5), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Insights',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5))),
                    const SizedBox(height: 4),
                    Text(dashboard.aiInsight,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Create Offer Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openCreateOfferScreen(context, controller),
            icon: const Icon(Icons.card_giftcard, color: Colors.white),
            label: const Text('Create New Offer',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Offer History
        const Text('Offer History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Text('Previously sent retention offers',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 12),

        if (dashboard.offerHistory.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No offers sent yet.',
                  style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...dashboard.offerHistory
              .map((o) => _buildHistoryCard(context, controller, o)),
      ],
    );
  }

  // Stat Card
  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(_iconForStat(label), color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  IconData _iconForStat(String label) {
    if (label == 'High Risk') return Icons.warning_amber_rounded;
    if (label == 'Mid Risk') return Icons.trending_down;
    return Icons.card_giftcard;
  }

  // History Card
  Widget _buildHistoryCard(BuildContext context,
      RetentionOfferController controller, OfferHistoryItem offer) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OfferDetailsScreen(
              token: token, gymId: gymId, offerId: offer.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Sent: ${offer.createdAt}',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _chip('${offer.membersCount} members',
                    const Color(0xFFEEEEEE), Colors.black87),
                const SizedBox(height: 4),
                _chip(
                    controller.formatTargetType(offer.targetType),
                    const Color(0xFFF0EEFF),
                    const Color(0xFF4F46E5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  // Open Create Offer Screen
  void _openCreateOfferScreen(
      BuildContext context, RetentionOfferController controller) async {
    controller.loadPreview();

    final sent = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateOfferScreen(
          controller: controller,
          maxMembers: controller.dashboard!.totalActiveMembers,
        ),
      ),
    );

    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}