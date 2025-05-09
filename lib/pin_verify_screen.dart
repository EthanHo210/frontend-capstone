import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

class PinVerifyScreen extends StatefulWidget {
  const PinVerifyScreen({super.key});

  @override
  State<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends State<PinVerifyScreen> {
  final TextEditingController _pinController = TextEditingController();

  void _verifyPin() {
    final String correctPin = MockDatabase().adminPin; // Safe fetch from database

    if (_pinController.text.trim() == correctPin) {
      Navigator.pushReplacementNamed(context, '/manage_users');
    } else {
      _showError('Incorrect PIN. Please try again.');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error', style: GoogleFonts.poppins()),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            child: Text('OK', style: GoogleFonts.poppins()),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Enter Admin PIN', style: GoogleFonts.poppins(color: AppColors.blueText, fontWeight: FontWeight.bold)),
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
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter 4-digit PIN',
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
                onPressed: _verifyPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueText,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: Text('Verify', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}