import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'main_dashboard.dart'; // ✅ For both teacher and student for now
import 'app_colors.dart';

class LoginScreen extends StatefulWidget {
  // make these optional so existing code that used `const LoginScreen()` doesn't break
  final bool isDarkMode;
  final ValueChanged<bool>? onToggleTheme;

  const LoginScreen({
    super.key,
    this.isDarkMode = false,
    this.onToggleTheme,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameOrEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final MockDatabase _db = MockDatabase();

  void _login() {
    final usernameOrEmail = _usernameOrEmailController.text.trim();
    final password = _passwordController.text;

    if (usernameOrEmail.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    bool isAuthenticated = _db.authenticate(usernameOrEmail, password);

    if (isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainDashboard(
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme, // same logic as Login’s button
          ),
        ),
      );

    } else {
      _showError('Invalid email or password.');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _goToResetPassword() {
    Navigator.pushNamed(context, '/passwordreset');
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppColors.blueText;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // simple icon-only button (keeps your earlier look)
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
              color: textColor,
            ),
            onPressed: () => widget.onToggleTheme?.call(!widget.isDarkMode),
          ),

          // If you'd prefer a button with an icon + text, swap in the TextButton.icon below:
          /*
          TextButton.icon(
            onPressed: () => widget.onToggleTheme?.call(!widget.isDarkMode),
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round, color: textColor),
            label: Text(widget.isDarkMode ? 'Light' : 'Dark', style: TextStyle(color: textColor)),
          ),
          */
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'To',
                    style: GoogleFonts.kavoon(
                      textStyle: TextStyle(
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
                      textStyle: TextStyle(
                        color: const Color.fromRGBO(42, 49, 129, 1),
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
              const SizedBox(height: 16),
              Text(
                'Welcome!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildInputField(_usernameOrEmailController, 'Email or username'),
              const SizedBox(height: 20),
              _buildInputField(_passwordController, 'Password', obscure: true),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueText, // Always blue background
                  foregroundColor: Colors.white,       // Always white text
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                ),
                child: const Text('SIGN IN'),
              ),


              const SizedBox(height: 20),
              TextButton(
                onPressed: _goToResetPassword,
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hintText, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.blue[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
