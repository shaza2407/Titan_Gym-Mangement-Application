import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/offer_details_model.dart';
import '../controller/offer_details_controller.dart';

class OfferDetailsScreen extends StatelessWidget {
  final String token;
  final int gymId;
  final int offerId;

  const OfferDetailsScreen({
    super.key,
    required this.token,
    required this.gymId,
    required this.offerId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OfferDetailsController(
        gymId:   gymId,
        offerId: offerId,
        token:   token,
      ),
      child: const _OfferDetailsView(),
    );
  }
}

class _OfferDetailsView extends StatelessWidget {
  const _OfferDetailsView();

  static const _accent = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OfferDetailsController>();

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
            Text('Offer Details',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text('Retention offer summary',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.errorMessage != null
              ? Center(
                  child: Text(controller.errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : _buildBody(controller),
    );
  }

  // Body
  Widget _buildBody(OfferDetailsController controller) {
    final offer = controller.offer!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _summaryCard(offer),
          const SizedBox(height: 16),
          _infoCard(offer, controller),
          const SizedBox(height: 16),
          _recipientsCard(offer.recipients, controller),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Summary Card
  Widget _summaryCard(OfferDetailsModel offer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.card_giftcard, color: _accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(offer.description,
                    style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Info Card
  Widget _infoCard(
      OfferDetailsModel offer, OfferDetailsController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Offer Info',
              style:
                  TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _infoRow(Icons.label_outline, 'Type',
              controller.formatOfferType(offer.offerType)),
          _divider(),
          _infoRow(Icons.radio_button_checked, 'Benefit', offer.benefit),
          _divider(),
          _infoRow(Icons.calendar_today_outlined, 'Sent On',
              controller.formatDate(offer.sentAt)),
          _divider(),
          _infoRow(Icons.access_time, 'Valid Until',
              controller.formatDate(offer.validUntil)),
          _divider(),
          _infoRow(Icons.people_outline, 'Target Group',
              controller.formatTargetType(offer.targetType)),
          _divider(),
          _recipientsCountRow(offer.numberOfMembers),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: _accent, size: 18),
          const SizedBox(width: 10),
          Text(label,
              style:
                  const TextStyle(color: Colors.black54, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _recipientsCountRow(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.group_outlined, color: _accent, size: 18),
          const SizedBox(width: 10),
          const Text('Recipients',
              style: TextStyle(color: Colors.black54, fontSize: 14)),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count members',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0));

  // Recipients Card
  Widget _recipientsCard(List<OfferRecipientModel> recipients,
      OfferDetailsController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recipients',
              style:
                  TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Members this offer was sent to',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          if (recipients.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No recipients',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...recipients.map((r) => _memberRow(r, controller)),
        ],
      ),
    );
  }

  Widget _memberRow(
      OfferRecipientModel r, OfferDetailsController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(r.email,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: controller.riskColor(r.riskLevel),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(r.riskLevel,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}