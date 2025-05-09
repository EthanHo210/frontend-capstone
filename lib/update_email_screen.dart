import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';


class UpdateEmailScreen extends StatefulWidget {
  const UpdateEmailScreen({super.key});

  @override
  State<UpdateEmailScreen> createState() => _UpdateEmailScreenState();
}

class _UpdateEmailScreenState extends State<UpdateEmailScreen> {
  final TextEditingController _newEmailController = TextEditingController();

  void _updateEmail() {
    String newEmail = _newEmailController.text.trim();
    if (newEmail.isEmpty || !newEmail.contains('@')) {
      _showSnackBar('Please enter a valid email.');
      return;
    }

    bool success = MockDatabase().updateEmail(newEmail);
    if (success) {
      _showSnackBar('Email updated successfully.');
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context); // Go back to Settings after update
      });
    } else {
      _showSnackBar('Failed to update email.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: AppColors.blueText,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Light pastel yellow background
      appBar: AppBar(
        title: Text(
          'Update Email',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.blueText,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.blueText),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _newEmailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  hintText: 'Enter new email',
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
                onPressed: _updateEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueText,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Update Email',
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
