import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final MockDatabase _db = MockDatabase();
  String searchQuery = '';

  void _deleteUser(String username) {
    final user = _db.getUserByUsername(username);
    if (user == null) return;

    if (user['role'] == 'admin') {
      final adminCount = _db.getAllUsers().where((u) => u['role'] == 'admin').length;
      if (adminCount <= 1) {
        _showError('You cannot delete the only remaining admin.');
        return;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete User'),
          ],
        ),
        content: Text('Are you sure you want to permanently delete "$username"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _db.deleteUser(username);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editUser(Map<String, dynamic> user) {
    final usernameController = TextEditingController(text: user['username']);
    final fullNameController = TextEditingController(text: user['fullName'] ?? '');
    final emailController = TextEditingController(text: user['email']);
    final passwordController = TextEditingController();
    String selectedRole = user['role'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(fullNameController, 'Full Name'),
              const SizedBox(height: 8),
              _buildTextField(usernameController, 'Username'),
              const SizedBox(height: 8),
              _buildTextField(emailController, 'Email'),
              const SizedBox(height: 8),
              _buildTextField(passwordController, 'New Password (optional)', obscure: true),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: ['user', 'teacher', 'officer', 'admin'].map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedRole = value;
                },
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            onPressed: () {
              final newUsername = usernameController.text.trim();
              final newFullName = fullNameController.text.trim();
              final newEmail = emailController.text.trim();
              final newPassword = passwordController.text.trim();

              if (newUsername.isEmpty || newEmail.isEmpty) {
                _showError('Username and email cannot be empty.');
                return;
              }

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Edit'),
                  content: Text('Are you sure you want to apply these changes to "${user['username']}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        _db.updateUser(
                          user['username'],
                          newEmail,
                          newPassword.isEmpty ? user['password'] : newPassword,
                          selectedRole,
                          newUsername: newUsername,
                        );
                        user['fullName'] = newFullName;
                        setState(() {});
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final usernameController = TextEditingController();
    final fullNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'user';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(fullNameController, 'Full Name'),
              const SizedBox(height: 8),
              _buildTextField(usernameController, 'Username'),
              const SizedBox(height: 8),
              _buildTextField(emailController, 'Email'),
              const SizedBox(height: 8),
              _buildTextField(passwordController, 'Password', obscure: true),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: ['user', 'teacher', 'officer', 'admin'].map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedRole = value;
                },
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            onPressed: () {
              final username = usernameController.text.trim();
              final fullName = fullNameController.text.trim();
              final email = emailController.text.trim();
              final password = passwordController.text;

              if (username.isEmpty || email.isEmpty || password.isEmpty) {
                _showError('All fields are required.');
                return;
              }
              if (_db.isUsernameTaken(username)) {
                _showError('Username is already taken.');
                return;
              }
              if (_db.getUserByEmail(email) != null) {
                _showError('Email is already registered.');
                return;
              }
              _db.addUser({
                'username': username,
                'fullName': fullName,
                'email': email,
                'password': password,
                'role': selectedRole,
              });
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [TextButton(child: const Text('OK'), onPressed: () => Navigator.pop(context))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.blueText;
    final searchFillColor = isDarkMode ? Colors.grey[800] : Colors.white;

    final allUsers = _db.getAllUsers();
    final filteredUsers = allUsers.where((user) {
      final username = user['username'].toLowerCase();
      final email = user['email'].toLowerCase();
      final fullName = (user['fullName'] ?? '').toLowerCase();
      return username.contains(searchQuery.toLowerCase()) ||
            email.contains(searchQuery.toLowerCase()) ||
            fullName.contains(searchQuery.toLowerCase());
    }).toList();

    final Map<String, List<Map<String, dynamic>>> grouped = {
      'admin': [],
      'officer': [],
      'teacher': [],
      'user': [],
    };
    for (var user in filteredUsers) {
      final role = user['role'] ?? 'user';
      grouped[role]?.add(user);
    }
    for (var role in grouped.keys) {
      grouped[role]!.sort((a, b) => (a['fullName'] ?? a['username'])
          .compareTo(b['fullName'] ?? b['username']));
    }

    final roleOrder = ['admin', 'officer', 'teacher', 'user'];
    final roleLabels = {
      'admin': 'Administrators',
      'officer': 'Officers',
      'teacher': 'Teachers',
      'user': 'Students',
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Manage Users',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                filled: true,
                fillColor: searchFillColor,
                prefixIcon: Icon(Icons.search,
                    color: isDarkMode ? Colors.white70 : Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: roleOrder.expand((role) {
          final usersInGroup = grouped[role]!;
          if (usersInGroup.isEmpty) return <Widget>[];

          return [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                roleLabels[role]!,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textColor,
                ),
              ),
            ),
            ...usersInGroup.map((user) => Card(
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(
                      user['fullName'] ?? user['username'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Username: ${user['username']}\n${user['email']}',
                      style: GoogleFonts.poppins(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editUser(user),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(user['username']),
                        ),
                      ],
                    ),
                  ),
                )),
          ];
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blueText,
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add User',
      ),
    );
  }

}
