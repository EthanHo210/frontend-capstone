import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'admin_dashboard.dart';
import 'main_dashboard.dart';
import 'app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
      final role = _db.getUserRole(usernameOrEmail);
      final email = _db.getEmailByUsername(usernameOrEmail) ?? usernameOrEmail;
      final username = _db.getUsernameByEmail(usernameOrEmail) ?? usernameOrEmail.split('@')[0];

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainDashboard(),
          ),
        );
      }
    } else {
      _showError('Invalid username/email or password.');
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Together!',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blueText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  color: AppColors.blueText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildInputField(_usernameOrEmailController, 'Email or Username'),
              const SizedBox(height: 20),
              _buildInputField(_passwordController, 'Password', obscure: true),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueText,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                    color: AppColors.blueText,
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
        fillColor: Colors.blue[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
