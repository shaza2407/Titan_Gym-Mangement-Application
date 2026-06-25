import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';

class OfferDetailsScreen extends StatefulWidget{
  final String token;
  final int gymId, offerId;

  const OfferDetailsScreen({
    super.key,
    required this.token,
    required this.gymId,
    required this.offerId,
  });

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  Map<String, dynamic>? _offer;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AdminApiService.getOfferDetails(widget.gymId, widget.offerId, widget.token);
      setState(() {_offer = data; _loading = false;});
    } catch (e) {
      setState(() {_error = e.toString(); _loading = false;});
    }
  }

  /// Helper Functions
  String _fmt(String? iso){
    if(iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    const m = ['Jan','Feb','Mar','Apr','May','Jun', 'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _fmtOfferType(String? t) {
    switch (t) {
      case 'discount':return 'Discount';
      case 'supplements':return 'Supplements';
      case 'free_sessions':return 'Free Sessions';
      case 'membership_upgrade':return 'Membership Upgrade';
      default: return t ?? '-';
    }
  }

  String _fmtTargetType(String? t) {
    switch (t) {
      case 'highest_risk': return 'Highest Risk';
      case 'lowest_risk':return 'Lowest Risk';
      case 'all_members':return 'All Members';
      case 'manual_selection':return 'Manual Selection';
      default:return t ?? '-';
    }
  }

  /// Build
  @override
  Widget build(BuildContext context){
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
            Text('Offer Details', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Retention offer summary', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _error == null ? _buildBody()
          : Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
    );
  }

    Widget _buildBody() {
    final offer = _offer!;
    final recipients = (offer['recipients'] as List? ?? []).cast<Map<String, dynamic>>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _summaryCard(offer),
          const SizedBox(height: 16),
          _infoCard(offer),
          const SizedBox(height: 16),
          _recipientsCard(recipients),
          const SizedBox(height: 24),

        ],
      ),
    );
  }

  Widget _summaryCard(Map<String, dynamic> offer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.card_giftcard, color: Color(0xFF4F46E5), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(offer['description'] ?? '', style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _infoCard(Map<String, dynamic> offer) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Offer Info', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _row(Icons.label_outline, 'Type', _fmtOfferType(offer['offer_type'])),
          _divider(),
          _row(Icons.radio_button_checked, 'Benefit', offer['benefit'] ?? '-'),
          _divider(),
          _row(Icons.calendar_today_outlined,'Sent On', _fmt(offer['sent_at'])),
          _divider(),
          _row(Icons.access_time, 'Valid Until', _fmt(offer['valid_until'])),
          _divider(),
          _row(Icons.people_outline, 'Target Group', _fmtTargetType(offer['target_type'])),
          _divider(),
          _recipientsCountRow(offer['number_of_members'] ?? 0),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4F46E5), size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _recipientsCountRow(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.group_outlined, color: Color(0xFF4F46E5), size: 18),
          const SizedBox(width: 10),
          const Text('Recipients', style: TextStyle(color: Colors.black54, fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(border: Border.all(color: Colors.black26), borderRadius: BorderRadius.circular(20),),
            child: Text('$count members', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
       const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0));


  Widget _recipientsCard(List<Map<String, dynamic>> recipients) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recipients', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Members this offer was sent to', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          if (recipients.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No recipients', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...recipients.map(_memberRow),
        ],
      ),
    );
  }


  Widget _memberRow(Map<String, dynamic> r) {
    final risk = r['risk_level'] as String? ?? '';
    Color riskColor;
    if (risk.toLowerCase().contains('high')) {
      riskColor = Colors.red;
    } else if (risk.toLowerCase().contains('mid')) riskColor = Colors.orange;
    else riskColor = Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(r['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: riskColor, borderRadius: BorderRadius.circular(6)),
            child: Text(risk, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

}