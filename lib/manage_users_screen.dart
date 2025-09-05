import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

class ManageUsersScreen extends StatefulWidget {
  /// When true, renders content-only (no Scaffold/AppBar/FAB) so this can be
  /// embedded inside MainDashboard via `_wrapWithHeader`.
  final bool embedded;

  const ManageUsersScreen({super.key, this.embedded = false});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final MockDatabase _db = MockDatabase();

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===== Helpers =====

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(child: const Text('OK'), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _searchField({EdgeInsets padding = const EdgeInsets.all(12)}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final searchFillColor = isDarkMode ? Colors.grey[800] : Colors.white;

    return Padding(
      padding: padding,
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Search users...',
          hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
          filled: true,
          fillColor: searchFillColor,
          prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white70 : Colors.black54),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        onChanged: (value) => setState(() => searchQuery = value),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String label, {bool obscure = false}) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      onSubmitted: (_) {
        // no-op; dialogs handle submit with buttons
      },
    );
  }

  // ===== CRUD actions =====

  Future<void> _deleteUser(String username) async {
    final user = _db.getUserByUsername(username);
    if (user == null) return;

    if (user['role'] == 'admin') {
      final adminCount = _db.getAllUsers().where((u) => u['role'] == 'admin').length;
      if (adminCount <= 1) {
        _showError('You cannot delete the only remaining admin.');
        return;
      }
    }

    final confirmed = await showDialog<bool>(
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _db.deleteUser(username);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final usernameController = TextEditingController(text: user['username']);
    final fullNameController = TextEditingController(text: user['fullName'] ?? '');
    final emailController = TextEditingController(text: user['email']);
    final passwordController = TextEditingController();
    String selectedRole = user['role'] ?? 'user';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _textField(fullNameController, 'Full Name'),
                  const SizedBox(height: 8),
                  _textField(emailController, 'Email'),
                  const SizedBox(height: 8),
                  _textField(passwordController, 'New Password (optional)', obscure: true),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            actions: [
              TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
              ElevatedButton(
                onPressed: () {
                  final newUsername = usernameController.text.trim();
                  final newFullName = fullNameController.text.trim();
                  final newEmail = emailController.text.trim();
                  final newPassword = passwordController.text;

                  if (newUsername.isEmpty || newEmail.isEmpty) {
                    _showError('Username and email cannot be empty.');
                    return;
                  }
                  if (newUsername != user['username'] && _db.isUsernameTaken(newUsername)) {
                    _showError('Username is already taken.');
                    return;
                  }
                  final existingByEmail = _db.getUserByEmail(newEmail);
                  if (newEmail != user['email'] && existingByEmail != null) {
                    _showError('Email is already registered.');
                    return;
                  }

                  showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Edit'),
                      content: Text('Are you sure you want to apply these changes to "${user['username']}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            // Hash new password if provided; otherwise keep existing hash
                            final updatedPassword = newPassword.isEmpty
                                ? user['password']
                                : sha256.convert(utf8.encode(newPassword)).toString();

                            _db.updateUser(
                              user['username'],
                              newEmail,
                              updatedPassword,
                              selectedRole,
                              newUsername: newUsername,
                            );

                            // Update full name directly in the users list (in-memory)
                            final usersRef = _db.getAllUsers();
                            final idx = usersRef.indexWhere((u) => u['username'] == newUsername);
                            if (idx != -1) {
                              usersRef[idx]['fullName'] = newFullName;
                            }

                            // reflect immediately in local map (for current list tile)
                            user['username'] = newUsername;
                            user['fullName'] = newFullName;
                            user['email'] = newEmail;
                            user['role'] = selectedRole;

                            Navigator.pop(context, true); // close confirm
                            Navigator.pop(context, true); // close editor
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
          );
        });
      },
    );

    usernameController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();

    if (result == true) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated')));
    }
  }

  Future<void> _showAddUserDialog() async {
    final usernameController = TextEditingController();
    final fullNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'user';

    final added = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add New User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _textField(fullNameController, 'Full Name'),
                  const SizedBox(height: 8),
                  _textField(usernameController, 'Username'),
                  const SizedBox(height: 8),
                  _textField(emailController, 'Email'),
                  const SizedBox(height: 8),
                  _textField(passwordController, 'Password', obscure: true),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: ['user', 'teacher', 'officer', 'admin']
                        .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => selectedRole = value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Role',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
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

                  // IMPORTANT: pass RAW password; MockDatabase.addUser() hashes internally.
                  _db.addUser({
                    'username': username,
                    'fullName': fullName,
                    'email': email,
                    'password': password, // raw here
                    'role': selectedRole,
                  });

                  Navigator.pop(context, true);
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    );

    usernameController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();

    if (added == true) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User added')));
    }
  }

  // ===== UI =====

  Widget _buildUsersList(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.blueText;

    final allUsers = _db.getAllUsers();
    final filteredUsers = allUsers.where((user) {
      final username = (user['username'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final fullName = (user['fullName'] ?? '').toString().toLowerCase();
      final q = searchQuery.toLowerCase();
      return username.contains(q) || email.contains(q) || fullName.contains(q);
    }).toList();

    final Map<String, List<Map<String, dynamic>>> grouped = {
      'admin': [],
      'officer': [],
      'teacher': [],
      'user': [],
    };
    for (var user in filteredUsers) {
      final role = (user['role'] ?? 'user').toString();
      grouped[role]?.add(user);
    }
    for (var role in grouped.keys) {
      grouped[role]!.sort((a, b) =>
          (a['fullName'] ?? a['username']).toString().compareTo((b['fullName'] ?? b['username']).toString()));
    }

    final roleOrder = ['admin', 'officer', 'teacher', 'user'];
    final roleLabels = {
      'admin': 'Administrators',
      'officer': 'Officers',
      'teacher': 'Teachers',
      'user': 'Students',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: roleOrder.expand((role) {
        final usersInGroup = grouped[role]!;
        if (usersInGroup.isEmpty) return <Widget>[];

        return [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              roleLabels[role]!,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
            ),
          ),
          ...usersInGroup.map((user) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            final textColor = isDarkMode ? Colors.white : AppColors.blueText;
            final role = (user['role'] ?? 'user').toString();
            final fullName = (user['fullName'] ?? '').toString().trim();
            final displayName = fullName.isNotEmpty ? fullName : (user['username'] ?? '');

            return Card(
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(
                  displayName, // Full name on top (falls back to username)
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Username: ${user['username']}',
                        style: GoogleFonts.poppins(
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        )),
                    Text('Email: ${user['email']}',
                        style: GoogleFonts.poppins(
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        )),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.badge, size: 14),
                        const SizedBox(width: 6),
                        Text('Role: ${role[0].toUpperCase()}${role.substring(1)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            )),
                      ],
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editUser(user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteUser(user['username']),
                    ),
                  ],
                ),
              ),
            );
          }),
        ];
      }).toList(),
    );
  }

  Widget _embeddedContent() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final titleColor = Theme.of(context).textTheme.titleLarge?.color ?? (isDarkMode ? Colors.white : Colors.black);

    return Column(
      children: [
        // Header + inline Add User (so we don’t conflict with MainDashboard FAB)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Text('Users',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: titleColor)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddUserDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueText,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        _searchField(padding: const EdgeInsets.fromLTRB(12, 8, 12, 8)),
        Expanded(child: _buildUsersList(context)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      // Content-only for embedded usage
      return _embeddedContent();
    }

    // Standalone (legacy) full-screen route
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.blueText;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Manage Users', style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _searchField(),
        ),
      ),
      body: _buildUsersList(context),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blueText,
        onPressed: _showAddUserDialog,
        tooltip: 'Add User',
        child: const Icon(Icons.add),
      ),
    );
  }
}
