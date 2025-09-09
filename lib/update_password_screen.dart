import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'services/password_reset_service.dart';

class UpdatePasswordScreen extends StatefulWidget {
  /// If true, renders content-only (no Scaffold/AppBar) so it can be embedded
  /// inside other screens. Default false for standalone route.
  final bool embedded;

  const UpdatePasswordScreen({super.key, this.embedded = false});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  String? _token; // passed via route arguments
  String? _email; // optional, informational

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _token = args['token']?.toString();
      _email = args['email']?.toString();
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _validForm {
    final pw = _newPasswordController.text.trim();
    final cpw = _confirmController.text.trim();
    final otp = _otpController.text.trim();
    return _token != null &&
        otp.length == 6 &&
        int.tryParse(otp) != null &&
        pw.length >= 6 &&
        pw == cpw;
  }

  Future<void> _updatePassword() async {
    final token = _token?.trim();
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (token == null || token.isEmpty) {
      _showSnackBar('This reset link is invalid.');
      return;
    }
    if (otp.length != 6 || int.tryParse(otp) == null) {
      _showSnackBar('Please enter the 6-digit OTP from your email.');
      return;
    }
    if (newPassword.length < 6) {
      _showSnackBar('Password must be at least 6 characters.');
      return;
    }
    if (newPassword != _confirmController.text.trim()) {
      _showSnackBar('Passwords do not match.');
      return;
    }

    setState(() => _submitting = true);

    try {
      // First check OTP against this token
      final ok = PasswordResetService.instance.verifyOtp(token, otp);
      if (!ok) {
        _showSnackBar('Invalid or expired OTP/link.');
        return;
      }

      // Consume the request and update the DB password
      PasswordResetService.instance.consumeAndUpdatePassword(
        token: token,
        newPassword: newPassword,
      );

      if (!mounted) return;

      // Success
      await _showSuccessDialog();
      if (widget.embedded) {
        Navigator.maybePop(context);
      } else {
        // Adjust this route name to your login route if different:
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('StateError: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
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

  Future<void> _showSuccessDialog() {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Password updated', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Your password has been changed successfully. You can now sign in with your new password.',
          style: GoogleFonts.poppins(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final secondaryText =
        Theme.of(context).textTheme.bodyMedium?.color ?? (isDark ? Colors.white70 : Colors.grey[700]!);
    final inputFill = isDark ? Colors.grey[800] : Colors.blue[50];

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
              if (_email != null && _email!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Account: $_email',
                      style: GoogleFonts.poppins(fontSize: 13, color: secondaryText),
                    ),
                  ),
                ),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: GoogleFonts.poppins(color: primaryText),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Enter 6-digit OTP',
                  hintStyle: GoogleFonts.poppins(color: secondaryText.withOpacity(0.85)),
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.poppins(color: primaryText),
                decoration: InputDecoration(
                  hintText: 'Enter new password',
                  hintStyle: GoogleFonts.poppins(color: secondaryText.withOpacity(0.85)),
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off, color: secondaryText),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.poppins(color: primaryText),
                decoration: InputDecoration(
                  hintText: 'Confirm new password',
                  hintStyle: GoogleFonts.poppins(color: secondaryText.withOpacity(0.85)),
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off, color: secondaryText),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting || !_validForm ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueText,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.blueText.withOpacity(0.5),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _submitting ? 'UPDATING…' : 'Update Password',
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
                  '• Enter the OTP from the email\n• Minimum 6 characters\n• Use a mix of letters, numbers, and symbols for a stronger password',
                  style: GoogleFonts.poppins(fontSize: 12, color: secondaryText),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return SafeArea(top: false, bottom: false, child: body);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Update Password',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: primaryText),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryText),
      ),
      body: SafeArea(child: body),
    );
  }
}
