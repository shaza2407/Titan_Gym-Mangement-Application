// lib/features/admin/presentation/screens/class_form_screen.dart

import 'package:flutter/material.dart';
import 'package:frontend/features/admin/controller/admin_schedule_controller.dart';
import '../domain/schedule_model.dart';

class ClassFormScreen extends StatefulWidget {
  final String token;
  final int gymId;
  final AdminScheduleController controller;
  final ClassSessionModel? existing; // null = create mode

  const ClassFormScreen({
    super.key,
    required this.token,
    required this.gymId,
    required this.controller,
    this.existing,
  });

  @override
  State<ClassFormScreen> createState() => _ClassFormScreenState();
}

class _ClassFormScreenState extends State<ClassFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _durationController;
  late final TextEditingController _maxClientsController;

  int? _selectedCoachId;
  bool _isRecurring = true;
  String _selectedDay = 'monday';
  DateTime? _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);

  bool _isSubmitting = false;
  String? _error;

  bool get _isEditMode => widget.existing != null;

  static const _days = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _titleController      = TextEditingController(text: c?.title ?? '');
    _durationController   = TextEditingController(text: c?.duration.toString() ?? '60');
    _maxClientsController = TextEditingController(text: c?.maxClients.toString() ?? '15');
    _selectedCoachId      = c?.coachId;
    _isRecurring          = c?.isRecurring ?? true;
    _selectedDay          = c?.dayOfWeek ?? 'monday';
    if (c?.date != null) {
      _selectedDate = DateTime.tryParse(c!.date!);
    }
    if (c?.startTime != null) {
      final parts = c!.startTime.split(':');
      _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _maxClientsController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a class title');
      return;
    }
    if (_selectedCoachId == null) {
      setState(() => _error = 'Please select a coach');
      return;
    }
    if (!_isRecurring && _selectedDate == null) {
      setState(() => _error = 'Please pick a date');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final payload = <String, dynamic>{
      'title':        _titleController.text.trim(),
      'coach_id':     _selectedCoachId,
      'is_recurring': _isRecurring,
      'start_time':   _formatTime(_selectedTime),
      'duration':     int.tryParse(_durationController.text) ?? 60,
      'max_clients':  int.tryParse(_maxClientsController.text) ?? 15,
      if (_isRecurring) 'day_of_week': _selectedDay,
      if (!_isRecurring) 'date': _formatDate(_selectedDate!),
    };

    final success = _isEditMode
        ? await widget.controller.editClass(widget.token, widget.gymId, widget.existing!.id, payload)
        : await widget.controller.createClass(widget.token, widget.gymId, payload);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      setState(() => _error = widget.controller.errorMessage ?? 'Something went wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    final coaches = widget.controller.coaches;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'Edit Class' : 'Create New Class',
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Class Title'),
            TextField(controller: _titleController, decoration: _inputDecoration('e.g. Morning Yoga')),
            const SizedBox(height: 16),

            _buildLabel('Coach'),
            DropdownButtonFormField<int>(
              value: _selectedCoachId,
              hint: const Text('Select a coach'),
              items: coaches.map((c) => DropdownMenuItem(value: c.coachId, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _selectedCoachId = v),
              decoration: _inputDecoration(null),
            ),
            const SizedBox(height: 16),

            _buildLabel('Class Type'),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  _buildTypeOption('Recurring Weekly', true),
                  _buildTypeOption('One-Time', false),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_isRecurring) ...[
              _buildLabel('Day of Week'),
              DropdownButtonFormField<String>(
                value: _selectedDay,
                items: _days
                    .map((d) => DropdownMenuItem(value: d, child: Text(d[0].toUpperCase() + d.substring(1))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDay = v ?? _selectedDay),
                decoration: _inputDecoration(null),
              ),
            ] else ...[
              _buildLabel('Date'),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate != null ? _formatDate(_selectedDate!) : 'Select a date',
                        style: TextStyle(color: _selectedDate != null ? Colors.black : Colors.grey),
                      ),
                      const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            _buildLabel('Start Time'),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _selectedTime);
                if (picked != null) setState(() => _selectedTime = picked);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_selectedTime.format(context)),
                    const Icon(Icons.access_time, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Duration (min)'),
                      TextField(controller: _durationController, keyboardType: TextInputType.number, decoration: _inputDecoration('60')),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Max Clients'),
                      TextField(controller: _maxClientsController, keyboardType: TextInputType.number, decoration: _inputDecoration('15')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isEditMode ? 'Save Changes' : 'Create Class', style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      );

  InputDecoration _inputDecoration(String? hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  Widget _buildTypeOption(String label, bool value) {
    final selected = _isRecurring == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isRecurring = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              color: selected ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}