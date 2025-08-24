import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

class UpdatePasswordScreen extends StatefulWidget {
  /// If true, renders content-only (no Scaffold/AppBar) so it can be embedded
  /// inside MainDashboard. Default false for standalone route.
  final bool embedded;

  const UpdatePasswordScreen({super.key, this.embedded = false});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _valid =>
      _newPasswordController.text.trim().length >= 6 &&
      _newPasswordController.text.trim() == _confirmController.text.trim();

  void _updatePassword() {
    final newPassword = _newPasswordController.text.trim();

    if (newPassword.length < 6) {
      _showSnackBar('Password must be at least 6 characters.');
      return;
    }
    if (newPassword != _confirmController.text.trim()) {
      _showSnackBar('Passwords do not match.');
      return;
    }

    final success = MockDatabase().updatePassword(newPassword);
    if (success) {
      _showSnackBar('Password updated successfully.');
      Future.delayed(const Duration(seconds: 2), () {
        // When embedded, let the parent handle navigation; otherwise pop route
        if (!widget.embedded && mounted) Navigator.pop(context);
      });
    } else {
      _showSnackBar('Failed to update password.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.blueText,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        Theme.of(context).textTheme.bodyLarge?.color ??
            (isDark ? Colors.white : Colors.black);
    final secondaryText =
        Theme.of(context).textTheme.bodyMedium?.color ??
            (isDark ? Colors.white70 : Colors.grey[700]!);
    final inputFill = isDark ? Colors.grey[800] : Colors.blue[50];

    // Build the core body once (no SafeArea here)
    final body = Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!widget.embedded)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Update Password',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: primaryText,
                    ),
                  ),
                ),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.poppins(color: primaryText),
                decoration: InputDecoration(
                  hintText: 'Enter new password',
                  hintStyle:
                      GoogleFonts.poppins(color: secondaryText.withOpacity(0.85)),
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility : Icons.visibility_off,
                      color: secondaryText,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.poppins(color: primaryText),
                decoration: InputDecoration(
                  hintText: 'Confirm new password',
                  hintStyle:
                      GoogleFonts.poppins(color: secondaryText.withOpacity(0.85)),
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                      color: secondaryText,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _valid ? _updatePassword : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueText,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.blueText.withOpacity(0.5),
                    disabledForegroundColor: Colors.white70,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Update Password',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '• Minimum 6 characters\n• Use a mix of letters, numbers, and symbols for a stronger password',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Embedded: no local AppBar/Scaffold, avoid double top/bottom padding
    if (widget.embedded) {
      return SafeArea(top: false, bottom: false, child: body);
    }

    // Standalone route: provide AppBar + SafeArea
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Update Password',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryText),
      ),
      body: SafeArea(child: body),
    );
  }
}
