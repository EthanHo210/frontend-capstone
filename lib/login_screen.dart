  import 'package:flutter/material.dart';
  import 'mock_database.dart';
  import 'package:google_fonts/google_fonts.dart';


  class LoginScreen extends StatefulWidget {
    const LoginScreen({super.key});

    @override
    _LoginScreenState createState() => _LoginScreenState();
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
        String? email = _db.getEmailByUsername(usernameOrEmail) ?? usernameOrEmail;
        String? username = _db.getUsernameByEmail(usernameOrEmail) ?? usernameOrEmail.split('@')[0];
        String role = _db.getUserRole(usernameOrEmail);

        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
          arguments: {
            'email': email,
            'username': username,
            'isAdmin': (role == 'admin').toString(), // <-- Pass 'true' or 'false'
          },
        );
      } else {
        _showError('Invalid username/email or password.');
      }
    }

    void _showError(String message) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Login Error'),
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

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFFEFBEA),
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
                  'Welcome!',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: Colors.teal,
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
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: const Text('SIGN IN'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text('Register if you\'re not a member.'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/passwordreset');
                  },
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
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
          fillColor: Colors.green[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );
    }
  }
