// admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AdminDashboard extends StatefulWidget {
  /// When true, renders content only (no Scaffold/AppBar/FAB) so it can live
  /// inside MainDashboard via `_wrapWithHeader`.
  final bool embedded;
  const AdminDashboard({super.key, this.embedded = false});

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

        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Create New User',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, color: AppColors.blueText)),
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
                    decoration: _dropdownDecoration(),
                    onChanged: (v) => setStateDialog(() => selectedRole = v ?? 'user'),
                    items: ['user', 'teacher']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueText,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final username = usernameController.text.trim();
                  final email = emailController.text.trim();
                  final rawPassword = passwordController.text.trim();

                  if (username.isEmpty || email.isEmpty || rawPassword.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All fields are required.')),
                    );
                    return;
                  }

                  final hashed = sha256.convert(utf8.encode(rawPassword)).toString();
                  db.registerUserWithRole(username, email, hashed, selectedRole);

                  if (mounted) setState(() {});
                  Navigator.pop(context);
                },
                child: const Text('Create'),
              ),
            ],
          );
        });
      },
    );
  }

  InputDecoration _dropdownDecoration() => InputDecoration(
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.blue[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  Widget _buildInputField(TextEditingController c, String hint, {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
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

  void _manageUser(String oldUsername) {
    final user = db.getUserByUsername(oldUsername);
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final usernameController = TextEditingController(text: oldUsername);
        final emailController = TextEditingController(text: user['email']);
        final passwordController = TextEditingController();
        String selectedRole = user['role'];

        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Manage $oldUsername',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, color: AppColors.blueText)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: _dropdownDecoration().copyWith(hintText: 'Username'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: _dropdownDecoration().copyWith(hintText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _dropdownDecoration().copyWith(
                      hintText: 'New Password (leave blank to keep current)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: _dropdownDecoration(),
                    onChanged: (v) => setStateDialog(() => selectedRole = v ?? selectedRole),
                    items: ['user', 'teacher']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueText,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final newUsername = usernameController.text.trim();
                  final email = emailController.text.trim();
                  final newPassword = passwordController.text.trim();

                  if (newUsername.isEmpty || email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Username and Email cannot be empty.')),
                    );
                    return;
                  }

                  final updatedPassword = newPassword.isEmpty
                      ? user['password']
                      : sha256.convert(utf8.encode(newPassword)).toString();

                  db.updateUser(oldUsername, email, updatedPassword, selectedRole,
                      newUsername: newUsername);

                  if (mounted) setState(() {});
                  Navigator.pop(context);
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        });
      },
    );
  }

  void _deleteUser(String username) {
    if (username == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the super-admin.')),
      );
      return;
    }

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
        content: Text(
          'Are you sure you want to permanently delete "$username"? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              db.deleteUser(username);
              if (mounted) setState(() {});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = db.getAllUsers();

    // ——— Embedded mode (no Scaffold/AppBar/FAB) ———
    if (widget.embedded) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final titleColor =
          Theme.of(context).textTheme.titleLarge?.color ?? (isDark ? Colors.white : Colors.black);

      // Use a single ListView so the parent wrapper (which already provides Expanded)
      // can size us properly. The first item is a header (title + Create button).
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  child: Row(
                    children: [
                      Text('Users',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 18, color: titleColor)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _createNewUser,
                        icon: const Icon(Icons.add),
                        label: const Text('Create User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blueText,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          }

          final user = users[index - 1];
          final username = user['username'];

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(username,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, color: AppColors.blueText)),
              subtitle: Text(
                'Email: ${user['email']}\nRole: ${user['role']}',
                style: GoogleFonts.poppins(color: AppColors.blueText.withOpacity(0.8)),
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
      );
    }

    // ——— Legacy full-screen mode (kept for direct routes) ———
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
            Text('To',
                style: GoogleFonts.kavoon(
                  textStyle: const TextStyle(
                    color: Colors.red,
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    shadows: [Shadow(offset: Offset(4.0, 4.0), blurRadius: 1.5, color: Colors.white)],
                  ),
                )),
            Text('gether!',
                style: GoogleFonts.kavoon(
                  textStyle: const TextStyle(
                    color: Color.fromRGBO(42, 49, 129, 1),
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    shadows: [Shadow(offset: Offset(4.0, 4.0), blurRadius: 1.5, color: Colors.white)],
                  ),
                )),
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
              title: Text(username,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, color: AppColors.blueText)),
              subtitle: Text(
                'Email: ${user['email']}\nRole: ${user['role']}',
                style: GoogleFonts.poppins(color: AppColors.blueText.withOpacity(0.8)),
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
