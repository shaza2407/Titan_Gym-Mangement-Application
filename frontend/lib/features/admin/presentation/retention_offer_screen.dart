import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controller/retention_offer_controller.dart';
import '../data/retention_offer_model.dart';

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
      RetentionOfferController(token: token, gymId: gymId)
        ..loadDashboard(),
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
                  Text('Retention & Churn Prevention', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('AI-powered member retention', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),

            body: Column(
              children: [
                Expanded(
                  child: controller.isLoadingDashboard ? const Center(
                      child: CircularProgressIndicator())
                      : controller.dashboardError == null ? _buildBody(
                      context, controller)
                      : Center(child: Text(controller.dashboardError!,
                      style: const TextStyle(color: Colors.red))),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  /// Build Body
  Widget _buildBody(BuildContext context, RetentionOfferController controller){
    final dashboard = controller.dashboard!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
            children: [
            Expanded(child: _statCard('High Risk', '${dashboard.highRiskCount}', Colors.red)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Mid Risk', '${dashboard.midRiskCount}', Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Offers Sent', '${dashboard.offersSent}', const Color(0xFF4F46E5))),
          ],
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EEFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF4F46E5), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Insights', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                    const SizedBox(height: 4),
                    Text(dashboard.aiInsight, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        /// Create Offer Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showCreateOfferModal(context, controller),
            // onPressed: () {},
            icon: const Icon(Icons.card_giftcard, color: Colors.white),
            label: const Text('Create New Offer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text('Offer History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Text('Previously sent retention offers', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
          ...dashboard.offerHistory.map((o) => _buildHistoryCard(o)),
      ],
    );
  }


  //// Helpers
  /// 1- Stat Card
  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),),
      child: Column(
        children: [
          Icon(_iconForStat(label), color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  IconData _iconForStat(String label) {
    if (label == 'High Risk') return Icons.warning_amber_rounded;
    if (label == 'Mid Risk') return Icons.trending_down;
    return Icons.card_giftcard;
  }

  /// 2- History Card
  Widget _buildHistoryCard(OfferHistoryItem offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text('Sent: ${offer.createdAt}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _chip('${offer.membersCount} members', const Color(0xFFEEEEEE), Colors.black87),
              const SizedBox(height: 4),
              _chip(_formatTargetType(offer.targetType), const Color(0xFFF0EEFF), const Color(0xFF4F46E5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  String _formatTargetType(String t) {
    switch (t) {
      case 'highest_risk' : return 'Highest Risk';
      case 'lowest_risk' : return 'Lowest Risk';
      case 'all_members' : return 'All Members';
      case 'manual_selection': return 'Manual';
      default : return t;
    }
  }

  void _showCreateOfferModal(BuildContext context, RetentionOfferController controller) {
    final maxMembers = controller.dashboard!.totalActiveMembers;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final benefitCtrl = TextEditingController();
    final validUntilCtrl  = TextEditingController();
    final numberOfMembersCtrl = TextEditingController(text: '${controller.numberOfMembers}');
    DateTime? pickedDate;
    String? formError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return ChangeNotifierProvider.value(
          value: controller,
          child: Consumer<RetentionOfferController>(
            builder: (ctx, ctrl, _) {
              return StatefulBuilder(
                builder: (ctx, setState) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Create Retention Offer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text('Create and send a special offer to retain members', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          /// Offer Title
                          _label('Offer Title *'),
                          _textField(titleCtrl, 'e.g., Welcome Back Bonus'),
                          const SizedBox(height: 12),

                          /// offer Type
                          _label('Offer Type *'),
                          _dropdown(
                            value: ctrl.offerType,
                            items: const {
                              'discount' : 'Discount',
                              'supplements' : 'Supplements',
                              'free_sessions' : 'Free Sessions',
                              'membership_upgrade': 'Membership Upgrade',
                            },
                            onChanged: ctrl.setOfferType,
                          ),
                          const SizedBox(height: 12),

                          /// Description
                          _label('Description *'),
                          _textField(descCtrl, 'Describe the offer', maxLines: 3),
                          const SizedBox(height: 12),

                          /// Benefit
                          _label('Discount/Benefit *'),
                          _textField(benefitCtrl, 'e.g., 20% or 2 free sessions'),
                          const SizedBox(height: 12),

                          /// Valid Until
                          _label('Valid Until'),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: DateTime.now().add(const Duration(days: 30)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                pickedDate = picked;
                                validUntilCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                ctrl.notifyListeners();
                              }
                            },
                            child: AbsorbPointer(
                              child: _textField(validUntilCtrl, 'mm / dd / yyyy', suffix: const Icon(Icons.calendar_today, size: 18)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          /// Target Members
                          _label('Target Members *'),
                          _dropdown(
                            value: ctrl.targetType,
                            items: const {
                              'highest_risk' : 'Highest Risk',
                              'lowest_risk' : 'Lowest Risk',
                              'manual_selection': 'Manual Selection',
                              'all_members' : 'All Members',
                            },
                            onChanged: (val) {
                              ctrl.setTargetType(val);
                              ctrl.loadPreview();
                            },
                          ),
                          const SizedBox(height: 12),

                          // Number of Members (hidden for manual)
                          if (ctrl.targetType != 'manual_selection' && ctrl.targetType != 'all_members') ...[
                            _label('Number of Members'),
                            Container(
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: TextField(
                                        controller: numberOfMembersCtrl,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        style: const TextStyle(fontSize: 15),
                                        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                        onChanged: (val) {
                                          final parsed = int.tryParse(val);
                                          if (parsed == null) return; // user mid-edit (e.g. cleared the field)
                                          int clamped = parsed;
                                          if (clamped < 1) clamped = 1;
                                          if (clamped > maxMembers) clamped = maxMembers;
                                          ctrl.setNumberOfMembers(clamped);
                                          ctrl.loadPreview();
                                        },
                                        onEditingComplete: () {
                                          // snap back to a valid value if left empty/out of range
                                          numberOfMembersCtrl.text = '${ctrl.numberOfMembers}';
                                          numberOfMembersCtrl.selection = TextSelection.collapsed(offset: numberOfMembersCtrl.text.length);
                                        },
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                                        onPressed: () {
                                          if (ctrl.numberOfMembers < maxMembers) {
                                            final updated = ctrl.numberOfMembers + 1;
                                            ctrl.setNumberOfMembers(updated);
                                            numberOfMembersCtrl.text = '$updated';
                                            ctrl.loadPreview();
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                        onPressed: () {
                                          if (ctrl.numberOfMembers > 1) {
                                            final updated = ctrl.numberOfMembers - 1;
                                            ctrl.setNumberOfMembers(updated);
                                            numberOfMembersCtrl.text = '$updated';
                                            ctrl.loadPreview();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          /// Manual search & selection
                          if (ctrl.targetType == 'manual_selection') ...[
                            _label('Select Members (${ctrl.manualSelected.length} selected)'),
                            const SizedBox(height: 8),
                            _buildManualSearch(ctrl),
                            const SizedBox(height: 12),
                          ],

                          /// Preview list
                          _buildPreviewSection(ctrl),
                          const SizedBox(height: 16),


                          /// Error check
                          if (formError != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(formError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),


                            /// Send Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: ctrl.isSending ? null
                                    : () async {
                                        if (titleCtrl.text.trim().isEmpty || benefitCtrl.text.trim().isEmpty) {
                                          setState(() {
                                            formError = 'Please fill all required fields';
                                          });
                                          return;
                                        }
                                        setState(() => formError = null);
                                        await ctrl.sendOffer(
                                          title  : titleCtrl.text.trim(),
                                          description: descCtrl.text.trim(),
                                          benefit : benefitCtrl.text.trim(),
                                          validUntil : pickedDate != null ? validUntilCtrl.text : null,
                                        );
                                        if (ctrl.sendSuccess) {
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                            content: Text('Offer sent successfully!'),
                                            backgroundColor: Colors.green,
                                          ));
                                        }
                                      },
                                icon: ctrl.isSending
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Icon(Icons.send, color: Colors.white),
                                label: Text(
                                  ctrl.isSending ? 'Sending...' : 'Create & Send to ${_sendCount(ctrl)} Members',
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                              ),
                            ),

                        ]
                      ),
                    ),
                  );
              },
              );
            },
          ),
        );
      },
    );

    controller.loadPreview();
  }


  /// Helper Functions

  // Manual member search & checkboxes
  Widget _buildManualSearch(RetentionOfferController ctrl) {
    final searchCtrl = TextEditingController();
    return StatefulBuilder(builder: (context, setState) {
      final query = searchCtrl.text.toLowerCase();
      final filtered = ctrl.previewMembers.where((m) =>
              m.name.toLowerCase().contains(query) ||
              m.email.toLowerCase().contains(query)).toList();

      return Column(
        children: [
          TextField(
            controller: searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10),),
            child: ctrl.isLoadingPreview ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(),))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final m = filtered[i];
                      final selected = ctrl.manualSelected.contains(m.membershipId);
                      return CheckboxListTile(
                        dense: true,
                        value: selected,
                        onChanged: (_) => ctrl.toggleManualMember(m.membershipId),
                        title: Text('${m.name} - ${_riskLabel(m.churnRisk)} Risk', style: const TextStyle(fontSize: 13)),
                        activeColor: const Color(0xFF4F46E5),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }



  /// Preview section
  Widget _buildPreviewSection(RetentionOfferController ctrl) {
    if (ctrl.targetType == 'manual_selection') {
      final selected = ctrl.previewMembers.where((m) => ctrl.manualSelected.contains(m.membershipId))
          .toList();
      // if (selected.isEmpty) return const SizedBox.shrink();
      return _previewBox(selected);
    }

    if (ctrl.isLoadingPreview) {
      return const Center(child: CircularProgressIndicator());
    }
    // if (ctrl.previewMembers.isEmpty) return const SizedBox.shrink();
    return _previewBox(ctrl.previewMembers);
  }

  Widget _previewBox(List<MemberPreview> members) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF4F46E5), size: 16),
              const SizedBox(width: 6),
              Text('Preview: ${members.length} Members', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
            ],
          ),
          const SizedBox(height: 8),
          ...members.map((m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• ${m.name} - ${m.email} (${m.churnRisk} Risk)', style: const TextStyle(fontSize: 12),),
              )),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );


  Widget _textField(TextEditingController ctrl, String hint,
      {int maxLines = 1, Widget? suffix}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }


  Widget _dropdown({required String value, required Map<String, String> items, required void Function(String) onChanged,}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.entries.map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  int _sendCount(RetentionOfferController ctrl) {
    if (ctrl.targetType == 'manual_selection') {
      return ctrl.manualSelected.length;
    }
    return ctrl.previewMembers.length;
  }

  String _riskLabel(String risk) => risk;
}