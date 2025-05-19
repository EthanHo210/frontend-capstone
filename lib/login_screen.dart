import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'admin_main_hub_screen.dart'; // ✅ Make sure this exists
import 'main_dashboard.dart';       // ✅ For both teacher and student for now
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

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminMainHubScreen()),
        );
      } else if (role == 'teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainDashboard()), // Optional: StudentDashboard()
        );
      }
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
                  color: AppColors.blueText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildInputField(_usernameOrEmailController, 'Email'),
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
