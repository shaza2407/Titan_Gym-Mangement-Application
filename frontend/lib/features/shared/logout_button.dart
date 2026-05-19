import 'package:flutter/material.dart';
//reusable logout button for app bar, calls showLogoutDialog on press
//leading: IconButton(icon: const Icon(Icons.logout, color: Colors.black),onPressed: () => showLogoutDialog(context)),

void showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Sign Out',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'Are you sure you want to sign out?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/login');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
          ),
          child: const Text(
            'Sign Out',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}