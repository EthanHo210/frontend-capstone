import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final db = MockDatabase();

  void _createNewUser() {
    showDialog(
      context: context,
      builder: (context) {
        final usernameController = TextEditingController();
        final emailController = TextEditingController();
        final passwordController = TextEditingController();
        String selectedRole = 'user';

        return AlertDialog(
          title: Text(
            'Create New User',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.blueText),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInputField(usernameController, 'Username'),
                const SizedBox(height: 12),
                _buildInputField(emailController, 'Email'),
                const SizedBox(height: 12),
                _buildInputField(passwordController, 'Password', obscure: true),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.blue[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => selectedRole = value!),
                  items: ['user', 'teacher']
                      .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final username = usernameController.text.trim();
                final email = emailController.text.trim();
                final rawPassword = passwordController.text.trim();

                if (username.isEmpty || email.isEmpty || rawPassword.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Missing Information'),
                      content: const Text('All fields are required.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                final hashedPassword = sha256.convert(utf8.encode(rawPassword)).toString();

                db.registerUserWithRole(
                  username,
                  email,
                  hashedPassword,
                  selectedRole,
                );

                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
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

  void _manageUser(String oldUsername) {
    final user = db.getUserByUsername(oldUsername);
    if (user == null) return;

    final usernameController = TextEditingController(text: oldUsername);
    final emailController = TextEditingController(text: user['email']);
    final passwordController = TextEditingController(); // Empty by default
    String selectedRole = user['role'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Manage $oldUsername',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.blueText),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  hintText: 'Username',
                  filled: true,
                  fillColor: Colors.blue[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Colors.blue[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'New Password (leave blank to keep current)',
                  filled: true,
                  fillColor: Colors.blue[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.blue[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => selectedRole = value!),
                items: ['user', 'teacher']
                    .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final newUsername = usernameController.text.trim();
              final email = emailController.text.trim();
              final newPassword = passwordController.text.trim();
              final updatedPassword = newPassword.isEmpty ? user['password'] : newPassword;

              if (newUsername.isEmpty || email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Username and Email cannot be empty.')),
                );
                return;
              }

              db.updateUser(oldUsername, email, updatedPassword, selectedRole, newUsername: newUsername);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }



  void _deleteUser(String username) {
    if (username == 'admin') return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete User'),
          ],
        ),
        content: Text('Are you sure you want to permanently delete "$username"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              db.deleteUser(username);
              setState(() {});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final users = db.getAllUsers();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.blueText),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
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

      floatingActionButton: FloatingActionButton(
        onPressed: _createNewUser,
        backgroundColor: AppColors.blueText,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final username = user['username'];

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(username, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Email: ${user['email']}\nRole: ${user['role']}',
                style: GoogleFonts.poppins(),
              ),
              trailing: username == 'admin'
                  ? const Text('(Admin)', style: TextStyle(fontWeight: FontWeight.bold))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _manageUser(username),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(username),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
