import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/announcement_controller.dart';
import '../../domain/announcement_model.dart';
import '../../../shared/connectivity_helper.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final String token;
  final int gymId;

  const CreateAnnouncementScreen({
    super.key,
    required this.token,
    required this.gymId,
  });

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState
    extends State<CreateAnnouncementScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _titleCtrl      = TextEditingController();
  final _contentCtrl    = TextEditingController();

  static const _titleMaxLength   = 255;
  static const _contentMaxLength = 1000;

  String _selectedReceiver = 'Clients only';
  final List<String> _receiverOptions = [
    'Clients only',
    'Coaches only',
    'Clients and Coaches',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(() => setState(() {}));
    _contentCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  // Check connectivity before attempting the request
  final online = await ConnectivityHelper.isOnline();
  if (!online) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You are offline. Please try again when you\'re connected.')),
    );
    return;
  }

  final controller = context.read<AnnouncementController>();

  final success = await controller.createAnnouncement(
    token:  widget.token,
    gymId:  widget.gymId,
    request: CreateAnnouncementRequest(
      title:    _titleCtrl.text.trim(),
      content:  _contentCtrl.text.trim(),
      receiver: _selectedReceiver,
    ),
  );

  if (!mounted) return;

  if (success) {
    Navigator.pop(context, true);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(controller.submitError ?? 'Failed to create')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Consumer<AnnouncementController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Row(
              children: [
                Icon(Icons.announcement_sharp, color: Color(0xFF4F46E5)),
                SizedBox(width: 8),
                Text(
                  'New Announcement',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildDropdown(),
                  const SizedBox(height: 16),

                  // Title
                  const Text('Title',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleCtrl,
                    maxLength: _titleMaxLength,
                    decoration: InputDecoration(
                      hintText: 'Enter announcement title',
                      filled: true,
                      fillColor: Colors.white,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Title is required';
                      if (v.length > _titleMaxLength) {
                        return 'Title must be $_titleMaxLength characters or fewer';
                      }
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_titleCtrl.text.length}/$_titleMaxLength',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content
                  const Text('Content',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _contentCtrl,
                    maxLength: _contentMaxLength,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Write your announcement message',
                      filled: true,
                      fillColor: Colors.white,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Content is required';
                      if (v.length > _contentMaxLength) {
                        return 'Content must be $_contentMaxLength characters or fewer';
                      }
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_contentCtrl.text.length}/$_contentMaxLength',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: controller.isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Send Announcement',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedReceiver,
        decoration: const InputDecoration(
          labelText: 'Send to',
          border: InputBorder.none,
        ),
        items: _receiverOptions
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (v) => setState(() => _selectedReceiver = v!),
      ),
    );
  }
}