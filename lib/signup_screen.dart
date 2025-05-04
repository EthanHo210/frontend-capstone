import 'package:flutter/material.dart';
import 'mock_database.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _courseController = TextEditingController(); // NEW
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final MockDatabase _db = MockDatabase();

  void _signup() {
    final name = _nameController.text.trim();
    final dob = _dobController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final course = _courseController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if ([name, dob, username, email, course, password, confirmPassword].any((e) => e.isEmpty)) {
      _showError('Please fill in all fields.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    if (_db.isUsernameExists(username)) {
      _showError('Username already exists.');
      return;
    }

    if (_db.isEmailExists(email)) {
      _showError('Email already exists.');
      return;
    }

    _db.registerUser(username, email, password); // UPDATED

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Signup successful! Please log in.')),
    );

    Navigator.pop(context); // Go back to login
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Signup Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
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
        fillColor: Colors.green[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
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
              Text(
                'Together!',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Let\'s begin',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  color: Colors.teal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildInputField(_nameController, 'Your name'),
              const SizedBox(height: 20),
              _buildInputField(_dobController, 'Date of Birth'),
              const SizedBox(height: 20),
              _buildInputField(_usernameController, 'Username'),
              const SizedBox(height: 20),
              _buildInputField(_emailController, 'Email address'),
              const SizedBox(height: 20),
              _buildInputField(_passwordController, 'Password', obscure: true),
              const SizedBox(height: 20),
              _buildInputField(_confirmPasswordController, 'Confirm Password', obscure: true),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: const Text('BEGIN'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Back to Login',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
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
