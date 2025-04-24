import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _passwordStrength;
  Color? _strengthColor;

  final mockDB = MockDatabase();

  void _checkPasswordStrength(String password) {
    if (password.length < 8) {
      _passwordStrength = "Too short";
      _strengthColor = Colors.red;
    } else if (!RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      _passwordStrength = "Weak";
      _strengthColor = Colors.orange;
    } else if (!RegExp(r'[@#\\$%^&+=!]').hasMatch(password)) {
      _passwordStrength = "Medium";
      _strengthColor = Colors.yellow[800];
    } else {
      _passwordStrength = "Strong";
      _strengthColor = Colors.green;
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (mockDB.emailExists(email)) {
        _showDialog("This email has been used. Please try again.");
        return;
      }

      // Save the new user to the mock database
      mockDB.addUser(email, password);

      // Navigate to the dashboard after successful signup
      Navigator.pushNamed(
        context,
        '/dashboard',
        arguments: {'email': email},
      );
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Together!',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Let's begin",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInputField('Your name', controller: _nameController),
                _buildInputField('Date of Birth', controller: _dobController),
                _buildInputField('Email address', controller: _emailController, validator: (value) {
                  if (value == null || value.isEmpty) return "This field cannot be blank";
                  final emailRegex = RegExp(r"^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$");
                  if (!emailRegex.hasMatch(value)) return "Please enter a valid email address";
                  return null;
                }),
                _buildInputField('Password', obscureText: true, controller: _passwordController, onChanged: (val) {
                  setState(() {
                    _checkPasswordStrength(val);
                  });
                }, validator: (value) {
                  if (value == null || value.isEmpty) return "This field cannot be blank";
                  if (value.length < 8) return "Password can't be shorter than 8 characters.";
                  return null;
                }),
                if (_passwordStrength != null)
                  Row(
                    children: [
                      Text("Password: $_passwordStrength", style: TextStyle(color: _strengthColor)),
                    ],
                  ),
                _buildInputField('Confirm Password', obscureText: true, controller: _confirmPasswordController, validator: (value) {
                  if (value == null || value.isEmpty) return "This field cannot be blank";
                  if (value != _passwordController.text) return "Passwords do not match";
                  return null;
                }),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'BEGIN',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String hint,
      {bool obscureText = false,
      TextEditingController? controller,
      String? Function(String?)? validator,
      void Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.poppins(),
        validator: validator ?? (value) => value == null || value.isEmpty ? "This field cannot be blank" : null,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.greenAccent.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
