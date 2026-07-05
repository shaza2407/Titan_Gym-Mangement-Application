import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controller/retention_offer_controller.dart';
import '../../domain/retention_offer_model.dart';
import '../../../shared/connectivity_helper.dart';

class CreateOfferScreen extends StatefulWidget {
  final RetentionOfferController controller;
  final int maxMembers;

  const CreateOfferScreen({
    super.key,
    required this.controller,
    required this.maxMembers,
  });

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  final _titleCtrl       = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _benefitCtrl     = TextEditingController();
  final _validUntilCtrl  = TextEditingController();
  late final TextEditingController _numberOfMembersCtrl;

  DateTime? _pickedDate;
  String?   _formError;

  @override
  void initState() {
    super.initState();
    _numberOfMembersCtrl =
        TextEditingController(text: '${widget.controller.numberOfMembers}');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _benefitCtrl.dispose();
    _validUntilCtrl.dispose();
    _numberOfMembersCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.controller,
      child: Consumer<RetentionOfferController>(
        builder: (context, ctrl, _) => Scaffold(
          backgroundColor: const Color(0xFFEEF0F8),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Retention Offer',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text('Create and send a special offer to retain members',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Offer Title
                  _label('Offer Title *'),
                  _textField(_titleCtrl, 'e.g., Welcome Back Bonus'),
                  const SizedBox(height: 12),

                  // Offer Type
                  _label('Offer Type *'),
                  _dropdown(
                    value: ctrl.offerType,
                    items: const {
                      'discount':           'Discount',
                      'supplements':        'Supplements',
                      'free_sessions':      'Free Sessions',
                      'membership_upgrade': 'Membership Upgrade',
                    },
                    onChanged: ctrl.setOfferType,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  _label('Description *'),
                  _textField(_descCtrl, 'Describe the offer', maxLines: 3),
                  const SizedBox(height: 12),

                  // Benefit
                  _label('Discount/Benefit *'),
                  _textField(_benefitCtrl, 'e.g., 20% or 2 free sessions'),
                  const SizedBox(height: 12),

                  // Valid Until
                  _label('Valid Until'),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        ctrl.setValidUntil(picked);
                        setState(() {
                          _pickedDate = picked;
                          _validUntilCtrl.text =
                              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: _textField(
                        _validUntilCtrl,
                        'mm / dd / yyyy',
                        suffix: const Icon(Icons.calendar_today, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Target Members
                  _label('Target Members *'),
                  _dropdown(
                    value: ctrl.targetType,
                    items: const {
                      'highest_risk':     'Highest Risk',
                      'lowest_risk':      'Lowest Risk',
                      'manual_selection': 'Manual Selection',
                      'all_members':      'All Members',
                    },
                    onChanged: (val) {
                      ctrl.setTargetType(val);
                      ctrl.loadPreview();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Number of Members
                  if (ctrl.targetType != 'manual_selection' &&
                      ctrl.targetType != 'all_members') ...[
                    _label('Number of Members'),
                    _buildMemberCountStepper(ctrl),
                    const SizedBox(height: 12),
                  ],

                  // Manual Selection
                  if (ctrl.targetType == 'manual_selection') ...[
                    _label('Select Members (${ctrl.manualSelected.length} selected)'),
                    const SizedBox(height: 8),
                    _buildManualSearch(ctrl),
                    const SizedBox(height: 12),
                  ],

                  // Preview
                  _buildPreviewSection(ctrl),
                  const SizedBox(height: 16),

                  // Error
                  if (_formError != null)
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
                            child: Text(_formError!,
                                style: const TextStyle(color: Colors.red, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Send Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: ctrl.isSending ? null : () => _send(ctrl),
                      icon: ctrl.isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send, color: Colors.white),
                      label: Text(
                        ctrl.isSending ? 'Sending...' : 'Create & Send to ${_sendCount(ctrl)} Members',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _send(RetentionOfferController ctrl) async {
    if (_titleCtrl.text.trim().isEmpty || _benefitCtrl.text.trim().isEmpty) {
      setState(() => _formError = 'Please fill all required fields');
      return;
    }

    final online = await ConnectivityHelper.isOnline();
    if (!online) {
      setState(() => _formError = 'No internet connection. Please try again.');
      return;
    }
    setState(() => _formError = null);

    await ctrl.sendOffer(
      title:       _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      benefit:     _benefitCtrl.text.trim(),
      validUntil:  _pickedDate != null ? _validUntilCtrl.text : null,
    );

    if (ctrl.sendSuccess && mounted) {
      Navigator.pop(context, true); // return true so the caller knows to show the SnackBar
    }
  }

Widget _buildMemberCountStepper(RetentionOfferController ctrl) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _numberOfMembersCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed == null) return;
                  final clamped = parsed.clamp(1, widget.maxMembers);
                  ctrl.setNumberOfMembers(clamped);
                  ctrl.loadPreview();
                },
                onEditingComplete: () {
                  _numberOfMembersCtrl.text = '${ctrl.numberOfMembers}';
                  _numberOfMembersCtrl.selection =
                      TextSelection.collapsed(offset: _numberOfMembersCtrl.text.length);
                },
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                onPressed: ctrl.numberOfMembers < widget.maxMembers
                    ? () {
                        final updated = ctrl.numberOfMembers + 1;
                        ctrl.setNumberOfMembers(updated);
                        _numberOfMembersCtrl.text = '$updated';
                        ctrl.loadPreview();
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                onPressed: ctrl.numberOfMembers > 1
                    ? () {
                        final updated = ctrl.numberOfMembers - 1;
                        ctrl.setNumberOfMembers(updated);
                        _numberOfMembersCtrl.text = '$updated';
                        ctrl.loadPreview();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualSearch(RetentionOfferController ctrl) {
    final searchCtrl = TextEditingController();
    return StatefulBuilder(builder: (context, setInner) {
      final query = searchCtrl.text.toLowerCase();
      final filtered = ctrl.previewMembers
          .where((m) =>
              m.name.toLowerCase().contains(query) ||
              m.email.toLowerCase().contains(query))
          .toList();

      return Column(
        children: [
          TextField(
            controller: searchCtrl,
            onChanged: (_) => setInner(() {}),
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10)),
            child: ctrl.isLoadingPreview
                ? const Center(
                    child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
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
                        title: Text('${m.name} - ${m.churnRisk} Risk',
                            style: const TextStyle(fontSize: 13)),
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

  Widget _buildPreviewSection(RetentionOfferController ctrl) {
    if (ctrl.targetType == 'manual_selection') {
      final selected = ctrl.previewMembers
          .where((m) => ctrl.manualSelected.contains(m.membershipId))
          .toList();
      return _previewBox(selected);
    }
    if (ctrl.isLoadingPreview) {
      return const Center(child: CircularProgressIndicator());
    }
    return _previewBox(ctrl.previewMembers);
  }

  Widget _previewBox(List<MemberPreview> members) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF4F46E5), size: 16),
              const SizedBox(width: 6),
              Text('Preview: ${members.length} Members',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
            ],
          ),
          const SizedBox(height: 8),
          ...members.map((m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• ${m.name} - ${m.email} (${m.churnRisk} Risk)',
                    style: const TextStyle(fontSize: 12)),
              )),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _textField(TextEditingController ctrl, String hint, {int maxLines = 1, Widget? suffix}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
}

  Widget _dropdown({
    required String value,
    required Map<String, String> items,
    required void Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
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
}