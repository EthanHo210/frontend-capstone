import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';

class UpdateUsernameScreen extends StatefulWidget {
  const UpdateUsernameScreen({super.key});

  @override
  State<UpdateUsernameScreen> createState() => _UpdateUsernameScreenState();
}

class _UpdateUsernameScreenState extends State<UpdateUsernameScreen> {
  final TextEditingController _newUsernameController = TextEditingController();

  void _updateUsername() {
    String newUsername = _newUsernameController.text.trim();
    if (newUsername.isEmpty) {
      _showSnackBar('Username cannot be empty.');
      return;
    }

    bool success = MockDatabase().updateUsername(newUsername);
    if (success) {
      _showSnackBar('Username updated successfully.');
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context); // Go back after success
      });
    } else {
      _showSnackBar('Failed to update username.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Update Username',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _newUsernameController,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  hintText: 'Enter new username',
                  hintStyle: GoogleFonts.poppins(),
                  filled: true,
                  fillColor: Colors.greenAccent.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateUsername,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Update Username',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
