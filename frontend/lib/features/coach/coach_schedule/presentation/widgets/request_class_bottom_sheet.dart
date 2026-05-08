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

  Future<void> _submitClassRequest() async {
    // validation
    if (_nameController.text.isEmpty || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // NOTE: If using Android Emulator, use 10.0.2.2 instead of 127.0.0.1
      // If using a physical device, use your computer's actual WiFi IP address
      final url = Uri.parse(
        'http://10.0.2.2:8000/api/coach/${widget.coachId}/class-requests',
      );

      final response = await http.post(
        url,
        headers: {
          'content-type': 'application/json',
          // 'Authorization' : 'Bearer <token>'
        },
        body: jsonEncode({
          "class_name": _nameController.text,
          "gym_id": selectedGymId,
          "request_date": _dateController.text,
          "request_time": _timeController.text,
          "duration": int.tryParse(_durationController.text) ?? 45,
          "capacity": int.tryParse(_capacityController.text) ?? 20,
          "reason": _reasonController.text.isEmpty
              ? null
              : _reasonController.text,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context); // Close the sheet on success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Class request submitted successfully!"),
            ),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error: ${response.body}"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Network error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
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
            ),
            const SizedBox(height: 16),

            _buildLabel("Date * (YYYY-MM-DD)"),
            _buildTextField(
              "2026-05-08",
              Icons.calendar_today_outlined,
              controller: _dateController,
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
