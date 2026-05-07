import 'package:flutter/material.dart';

class RequestClassBottomSheet extends StatelessWidget {
  const RequestClassBottomSheet({super.key});

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
          mainAxisSize: MainAxisSize.min, // Hugs the content
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
                  "Request Class Time",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context), // Closes the sheet
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Form Fields
            _buildLabel("Class Type"),
            _buildTextField("e.g., Morning Cardio Blast", Icons.fitness_center),
            const SizedBox(height: 16),

            _buildLabel("Gym Location"),
            _buildTextField("Select Gym...", Icons.location_on_outlined, isDropdown: true),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Date"),
                      _buildTextField("Select Date", Icons.calendar_today_outlined),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Time"),
                      _buildTextField("00:00 AM", Icons.access_time),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 4. Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Handle form submission to FastAPI/Supabase here
                  Navigator.pop(context); // Close sheet after submit
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0E21), // Dark navy from your design
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Submit Request",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
  Widget _buildTextField(String hint, IconData icon, {bool isDropdown = false}) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
        suffixIcon: isDropdown ? Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600) : null,
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