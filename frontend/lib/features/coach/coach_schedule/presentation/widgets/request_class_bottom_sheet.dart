import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RequestClassScreen extends StatefulWidget {
  final int coachId;
  const RequestClassScreen({super.key, required this.coachId});

  @override
  State<RequestClassScreen> createState() => _RequestClassScreenState();
}

class _RequestClassScreenState extends State<RequestClassScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _gymlocationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  bool _isLoading = false;
  int? selectedGymId = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _gymlocationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    _capacityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _submitClassRequest() async {
    // validation
    final className = _nameController.text.trim();
    final gymLocation = _gymlocationController.text.trim();
    final requestDate = _dateController.text.trim();
    final requestTime = _timeController.text.trim();
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    final capacity = int.tryParse(_capacityController.text.trim()) ?? 0;

    if (className.isEmpty ||
        gymLocation.isEmpty ||
        requestDate.isEmpty ||
        requestTime.isEmpty ||
        duration <= 0 ||
        capacity <= 0) {
      _showMessage("Please fill in all required fields", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
        'http://127.0.0.1:8000/${widget.coachId}/class_requests/',
      );

      final response = await http.post(
        url,
        headers: {
          'content-type': 'application/json',
          // 'Authorization' : 'Bearer <token>'
        },
        body: jsonEncode({
          "class_name": className,
          "gym_location": gymLocation,
          "requested_date": requestDate,
          "requested_time": requestTime,
          "duration": duration,
          "max_capacity": capacity,
          "reason": _reasonController.text.trim().isEmpty
              ? null
              : _reasonController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context); // Close the sheet on success
        }
        _showMessage("Class request submitted successfully!");
      } else {
        final body = response.body.trim();
        final message = body.isEmpty
            ? "Error: HTTP ${response.statusCode}"
            : "Error: $body";
        _showMessage(message, isError: true);
      }
    } catch (e) {
      _showMessage("Network error: $e", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate != null) {
      final year = pickedDate.year.toString().padLeft(4, '0');
      final month = pickedDate.month.toString().padLeft(2, '0');
      final day = pickedDate.day.toString().padLeft(2, '0');
      _dateController.text = "$year-$month-$day";
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final hour = pickedTime.hour.toString().padLeft(2, '0');
      final minute = pickedTime.minute.toString().padLeft(2, '0');
      _timeController.text = "$hour:$minute:00";
    }
  }

  @override
  Widget build(BuildContext context) {
    // This padding ensures the sheet moves up when the keyboard appears!
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: 24 + bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. The little grey drag handle at the top
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Request New Class",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context), // Closes the sheet
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Submit your request to add a new class time",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // 3. Form Fields
            _buildLabel("Class Name *"),
            _buildTextField(
              "e.g., Morning Cardio Blast",
              Icons.fitness_center,
              controller: _nameController,
            ),
            const SizedBox(height: 16),

            _buildLabel("Gym Location *"),
            _buildTextField(
              "Select Gym...",
              Icons.location_on_outlined,
              isDropdown: true,
              controller: _gymlocationController,
            ),
            const SizedBox(height: 16),

            _buildLabel("Date * (YYYY-MM-DD)"),
            _buildTextField(
              "2026-05-08",
              Icons.calendar_today_outlined,
              controller: _dateController,
              readOnly: true,
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Time * (HH:MM:SS)"),
                      _buildTextField(
                        "07:00:00",
                        Icons.access_time,
                        controller: _timeController,
                        readOnly: true,
                        onTap: _pickTime,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Duration(min) *"),
                      _buildTextField(
                        "45",
                        Icons.timer_outlined,
                        controller: _durationController,
                        isNumber: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildLabel("Max Capacity *"),
            _buildTextField(
              "20",
              Icons.people_outline,
              controller: _capacityController,
              isNumber: true,
            ),
            const SizedBox(height: 16),

            _buildLabel("Reason for Request (Optional)"),
            _buildTextField(
              "Why is this class needed?",
              Icons.note_alt_outlined,
              controller: _reasonController,
            ),
            const SizedBox(height: 32),

            // 4. Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitClassRequest,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF0A0E21,
                  ), // Dark navy from your design
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Submit Request",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for labels
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  // Helper method for form fields to match your clean UI
  Widget _buildTextField(
    String hint,
    IconData icon, {
    bool isDropdown = false,
    TextEditingController? controller,
    bool isNumber = false,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
        suffixIcon: isDropdown
            ? Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600)
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.purple, width: 2),
        ),
      ),
    );
  }
}
