import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

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
          title: const Text('Create New User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password')),
              DropdownButton<String>(
                value: selectedRole,
                onChanged: (value) => setState(() => selectedRole = value!),
                items: ['user', 'teacher', 'admin']
                    .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                db.registerUserWithRole(
                  usernameController.text.trim(),
                  emailController.text.trim(),
                  passwordController.text.trim(),
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

  void _manageUser(String username) {
    final user = db.getUserByUsername(username);
    if (user == null) return;

    final emailController = TextEditingController(text: user['email']);
    final passwordController = TextEditingController(text: user['password']);
    String selectedRole = user['role'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage $username'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password')),
            DropdownButton<String>(
              value: selectedRole,
              onChanged: (value) => setState(() => selectedRole = value!),
              items: ['user', 'teacher', 'admin']
                  .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              db.updateUser(username, emailController.text.trim(), passwordController.text.trim(), selectedRole);
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
    if (username == 'admin') return; // Protect admin account
    db.deleteUser(username);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final users = db.getAllUsers();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Together!',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.blueText,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.blueText),
            tooltip: 'Log out',
            onPressed: () {
              db.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
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
              subtitle: Text('Email: ${user['email']}\nRole: ${user['role']}', style: GoogleFonts.poppins()),
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
