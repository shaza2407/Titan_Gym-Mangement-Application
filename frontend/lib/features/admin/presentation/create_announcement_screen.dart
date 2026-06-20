import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../shared/api_constants.dart';

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

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  static const _titleMaxLength = 255;
  static const _contentMaxLength = 1000;

  String _selectedReceiver = 'Clients only'; // ← private + matches list
  final List<String> _receiverOptions = [
    'Clients only',
    'Coaches only',
    'Clients and Coaches',
  ];

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final res = await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}/admin/gyms/${widget.gymId}/announcements'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'reciever': _selectedReceiver, 
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        final message =
            jsonDecode(res.body)['detail'] ?? 'Failed to create announcement';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
          Icon(Icons.announcement_sharp ,color:Color(0xFF4F46E5)),
          Text("  "),
          const Text(
          'New Announcement',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        ],)
        
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _dropdownField(
                label: 'Send to',
                value: _selectedReceiver,
                items: _receiverOptions,
                onChanged: (v) => setState(() => _selectedReceiver = v), 
              ),
              const SizedBox(height: 16),

              const Text('Title',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
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
                  if (v.isEmpty) return 'Title is required field';
                  if (v.length > _titleMaxLength) {
                    return 'Title must be $_titleMaxLength characters or fewer';
                  }
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_titleController.text.length}/$_titleMaxLength',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              
              const SizedBox(height: 16),

              const Text('Content',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
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
                  if (v.isEmpty) return 'This is required field';
                  if (v.length > _contentMaxLength) {
                    return 'Content must be $_contentMaxLength characters or fewer';
                  }
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_contentController.text.length}/$_contentMaxLength',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Send Announcement',
                          style:
                              TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: value,           // ← was initialValue (doesn't exist)
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
        items: items
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (v) => onChanged(v!),
      ),
    );
  }
}