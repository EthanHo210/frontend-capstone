import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'mock_database.dart';
import 'services/password_reset_service.dart'; // ⬅️ NEW helper (code below)

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _submitting = false;

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showDialog('Please enter your email address.');
      return;
    }
    // super-light email format check (enough for demo)
    if (!email.contains('@') || !email.contains('.')) {
      _showDialog('Please enter a valid email address.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final db = MockDatabase();
      final user = db.getUserByEmail(email);

      if (user == null) {
        _showDialog("We couldn't find an account with that email.");
        return;
      }

      // Create a reset request (token + 6-digit OTP), expires in 15 minutes.
      final req = PasswordResetService.instance.createRequestForEmail(email);

      if (!mounted) return;

      // Show a simulated email so testers can copy OTP or open reset page.
      _showSimulatedEmailSheet(
        email: email,
        otp: req.otp,
        token: req.token,
        expiresAt: req.expiresAt,
      );
    } catch (e) {
      _showDialog('An unexpected error occurred. Please try again.\n$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Password Reset', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showSimulatedEmailSheet({
    required String email,
    required String otp,
    required String token,
    required DateTime expiresAt,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.email_outlined, color: AppColors.blueText),
                const SizedBox(width: 8),
                Text('Simulated Email', style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 16, color: textColor)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Hi,\n\nWe received a request to reset the password for the account associated with $email.\n'
              'Use the OTP below or follow the button to open the reset form. '
              'This request expires at ${expiresAt.toLocal()}.\n',
              style: GoogleFonts.poppins(color: textColor),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your OTP (6-digit)', style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 6),
                  SelectableText(
                    otp,
                    style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 2,
                      color: AppColors.blueText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.lock_reset),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueText,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: Text('Open reset page', style: GoogleFonts.poppins(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(ctx); // close sheet
                  Navigator.pushNamed(
                    context,
                    '/update_password',
                    arguments: {
                      'token': token,
                      'email': email, // optional, for convenience
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Close', style: GoogleFonts.poppins(color: textColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'To',
                      style: GoogleFonts.kavoon(
                        textStyle: const TextStyle(
                          color: Colors.red,
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(
                              offset: Offset(4.0, 4.0),
                              blurRadius: 1.5,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      'gether!',
                      style: GoogleFonts.kavoon(
                        textStyle: const TextStyle(
                          color: Color.fromRGBO(42, 49, 129, 1),
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(
                              offset: Offset(4.0, 4.0),
                              blurRadius: 1.5,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Text(
                'Reset your password',
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppColors.blueText,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email address',
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.blue[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.white : AppColors.blueText,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                ),
                child: Text(
                  _submitting ? 'SENDING…' : 'RESET PASSWORD',
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Back to Login',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : AppColors.blueText,
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
