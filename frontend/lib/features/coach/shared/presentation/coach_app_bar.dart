import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget implements PreferredSizeWidget {
  const HeaderSection({super.key});

  @override
  // Makes the AppBar slightly taller to comfortably fit the title and subtitle
  Size get preferredSize => const Size.fromHeight(70.0);

  // --- LOGOUT LOGIC ---
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out of your account?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              // 1. Clear your saved auth tokens here (e.g., using SharedPreferences or SecureStorage)
              // await AuthService.clearTokens();
              
              // 2. Navigate back to the Login Screen and clear the route history
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              
              Navigator.pop(context); // Placeholder: closes dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logged out successfully")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              elevation: 0,
            ),
            child: const Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0, // Prevents color change on scroll in Material 3
      // Adds the subtle grey border at the bottom of the app bar
      shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      
      // Left side: The purple gym logo
      leadingWidth: 70, // Gives the logo some breathing room
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6), // Purple from your design
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.fitness_center, color: Colors.white, size: 24),
        ),
      ),
      
      // Center: Title and Subtitle
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Coach Dashboard",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 2),
          Text(
            "Welcome back, Coach!",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
      
      // Right side: Notifications and Logout
      actions: [
        // Notification Icon with Badge
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black87, size: 28),
              onPressed: () {
                // Navigate to notifications
              },
            ),
            Positioned(
              right: 8,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  "2",
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1),
                ),
              ),
            ),
          ],
        ),
        
        // Logout Icon
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.black87, size: 24),
          onPressed: () => _handleLogout(context),
        ),
        const SizedBox(width: 8), // Right padding
      ],
    );
  }
}