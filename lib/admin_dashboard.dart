// admin_dashboard.dart
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'mock_database.dart';

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

  // ------- Shared UI helpers -------

  InputDecoration _fieldDecoration(String hint) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
      ),
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  ButtonStyle get _primaryBtnStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.button,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  ButtonStyle get _dangerBtnStyle => ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  // ------- Dialogs -------

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
            title: Text(
              'Create New User',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: _fieldDecoration('Username'),
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: _fieldDecoration('Email'),
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _fieldDecoration('Password'),
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: const ['user', 'teacher']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setStateDialog(() => selectedRole = v ?? 'user'),
                    decoration: _fieldDecoration('Role'),
                    style: GoogleFonts.poppins(),
                    dropdownColor: Theme.of(context).cardColor,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                style: _primaryBtnStyle,
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
                child: Text('Create', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        });
      },
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
            title: Text(
              'Manage $oldUsername',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: _fieldDecoration('Username'),
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: _fieldDecoration('Email'),
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _fieldDecoration('New Password (leave blank to keep current)'),
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: const ['user', 'teacher']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setStateDialog(() => selectedRole = v ?? selectedRole),
                    decoration: _fieldDecoration('Role'),
                    style: GoogleFonts.poppins(),
                    dropdownColor: Theme.of(context).cardColor,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                style: _primaryBtnStyle,
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

                  db.updateUser(
                    oldUsername,
                    email,
                    updatedPassword,
                    selectedRole,
                    newUsername: newUsername,
                  );

                  if (mounted) setState(() {});
                  Navigator.pop(context);
                },
                child: Text('Save Changes', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
          children: [
            Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text('Delete User', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "$username"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: _dangerBtnStyle,
            onPressed: () {
              db.deleteUser(username);
              if (mounted) setState(() {});
              Navigator.pop(context);
            },
            child: Text('Confirm', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ------- UI -------

  @override
  Widget build(BuildContext context) {
    final users = db.getAllUsers();
    final theme = Theme.of(context);
    final titleColor =
        theme.textTheme.titleLarge?.color ?? theme.colorScheme.onSurface;
    final bodyColor =
        theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurfaceVariant;

    // Embedded mode (no Scaffold/AppBar/FAB)
    if (widget.embedded) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        'Users',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: titleColor,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _createNewUser,
                        icon: const Icon(Icons.add),
                        label: Text('Create User', style: GoogleFonts.poppins()),
                        style: _primaryBtnStyle,
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
            color: theme.cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(
                username,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: titleColor),
              ),
              subtitle: Text(
                'Email: ${user['email']}\nRole: ${user['role']}',
                style: GoogleFonts.poppins(color: bodyColor),
              ),
              trailing: username == 'admin'
                  ? Text('(Admin)',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: bodyColor,
                      ))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit user',
                          icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                          onPressed: () => _manageUser(username),
                        ),
                        IconButton(
                          tooltip: 'Delete user',
                          icon: Icon(Icons.delete, color: theme.colorScheme.error),
                          onPressed: () => _deleteUser(username),
                        ),
                      ],
                    ),
            ),
          );
        },
      );
    }

    // Legacy full-screen mode (kept for direct routes)
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: titleColor),
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
                  shadows: [Shadow(offset: Offset(4.0, 4.0), blurRadius: 1.5, color: Colors.white)],
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
                  shadows: [Shadow(offset: Offset(4.0, 4.0), blurRadius: 1.5, color: Colors.white)],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewUser,
        backgroundColor: AppColors.button,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final username = user['username'];

          return Card(
            color: theme.cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(
                username,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: titleColor),
              ),
              subtitle: Text(
                'Email: ${user['email']}\nRole: ${user['role']}',
                style: GoogleFonts.poppins(color: bodyColor),
              ),
              trailing: username == 'admin'
                  ? Text('(Admin)',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: bodyColor,
                      ))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit user',
                          icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                          onPressed: () => _manageUser(username),
                        ),
                        IconButton(
                          tooltip: 'Delete user',
                          icon: Icon(Icons.delete, color: theme.colorScheme.error),
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
