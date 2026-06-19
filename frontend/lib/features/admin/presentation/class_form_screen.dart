// lib/features/admin/presentation/screens/class_form_screen.dart

import 'package:flutter/material.dart';
import 'package:frontend/features/admin/controller/admin_schedule_controller.dart';
import '../domain/schedule_model.dart';

// Simple, consistent palette used throughout this screen.
class _Palette {
  static const primary = Color.fromARGB(255, 85, 58, 182); // deep teal
  static const primaryTint = Color(0xFFE3F4F1); // soft teal background
  static const background = Color(0xFFF6F7FB);
  static const card = Colors.white;
  static const border = Color(0xFFE7E9EF);
  static const fieldFill = Color(0xFFF2F3F7);
  static const textPrimary = Color(0xFF1A1D29);
  static const textMuted = Color(0xFF7B8094);
  static const error = Color(0xFFE0524B);
  static const errorTint = Color(0xFFFCEAE9);
}

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
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _titleController = TextEditingController(text: c?.title ?? '');
    _durationController = TextEditingController(
      text: c?.duration.toString() ?? '60',
    );
    _maxClientsController = TextEditingController(
      text: c?.maxClients.toString() ?? '15',
    );
    _selectedCoachId = c?.coachId;
    _isRecurring = c?.isRecurring ?? true;
    _selectedDay = c?.dayOfWeek ?? 'monday';
    if (c?.date != null) {
      _selectedDate = DateTime.tryParse(c!.date!);
    }
    if (c?.startTime != null) {
      final parts = c!.startTime.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
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
      'title': _titleController.text.trim(),
      'coach_id': _selectedCoachId,
      'is_recurring': _isRecurring,
      'start_time': _formatTime(_selectedTime),
      'duration': int.tryParse(_durationController.text) ?? 60,
      'max_clients': int.tryParse(_maxClientsController.text) ?? 15,
      if (_isRecurring) 'day_of_week': _selectedDay,
      if (!_isRecurring) 'date': _formatDate(_selectedDate!),
    };

    final success = _isEditMode
        ? await widget.controller.editClass(
            widget.token,
            widget.gymId,
            widget.existing!.id,
            payload,
          )
        : await widget.controller.createClass(
            widget.token,
            widget.gymId,
            payload,
          );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      setState(
        () => _error = widget.controller.errorMessage ?? 'Something went wrong',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final coaches = widget.controller.coaches;

    return Scaffold(
      backgroundColor: _Palette.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: _Palette.border, width: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _Palette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _Palette.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 16,
                color: _Palette.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _isEditMode ? 'Edit Class' : 'Create New Class',
              style: const TextStyle(
                color: _Palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              icon: Icons.info_outline,
              title: 'Class Details',
              children: [
                _buildLabel('Class Title'),
                TextField(
                  controller: _titleController,
                  decoration: _inputDecoration('e.g. Morning Yoga'),
                ),
                const SizedBox(height: 16),

                _buildLabel('Coach'),
                DropdownButtonFormField<int>(
                  value: _selectedCoachId,
                  hint: const Text('Select a coach'),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _Palette.primary,
                  ),
                  items: coaches
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.coachId,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCoachId = v),
                  decoration: _inputDecoration(null),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.event_outlined,
              title: 'Schedule',
              children: [
                _buildLabel('Class Type'),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _Palette.fieldFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _Palette.primary,
                    ),
                    items: _days
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(d[0].toUpperCase() + d.substring(1)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedDay = v ?? _selectedDay),
                    decoration: _inputDecoration(null),
                  ),
                ] else ...[
                  _buildLabel('Date'),
                  _buildPickerTile(
                    icon: Icons.calendar_today,
                    text: _selectedDate != null
                        ? _formatDate(_selectedDate!)
                        : 'Select a date',
                    filled: _selectedDate != null,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: _Palette.primary,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null)
                        setState(() => _selectedDate = picked);
                    },
                  ),
                ],
                const SizedBox(height: 16),

                _buildLabel('Start Time'),
                _buildPickerTile(
                  icon: Icons.access_time,
                  text: _selectedTime.format(context),
                  filled: true,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: _Palette.primary,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _selectedTime = picked);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.groups_outlined,
              title: 'Capacity',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Duration (min)'),
                          TextField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('60'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Max Clients'),
                          TextField(
                            controller: _maxClientsController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('15'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _Palette.errorTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: _Palette.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: _Palette.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Palette.primary,
                  disabledBackgroundColor: _Palette.primary.withOpacity(0.6),
                  elevation: 0,
                  shadowColor: _Palette.primary.withOpacity(0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditMode ? 'Save Changes' : 'Create Class',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _Palette.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _Palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: _Palette.textMuted,
      ),
    ),
  );

  InputDecoration _inputDecoration(String? hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _Palette.textMuted),
    filled: true,
    fillColor: _Palette.fieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _Palette.primary, width: 1.5),
    ),
  );

  Widget _buildPickerTile({
    required IconData icon,
    required String text,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _Palette.fieldFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                color: filled ? _Palette.textPrimary : _Palette.textMuted,
                fontWeight: filled ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: _Palette.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: _Palette.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String label, bool value) {
    final selected = _isRecurring == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isRecurring = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _Palette.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              color: selected ? Colors.white : _Palette.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
