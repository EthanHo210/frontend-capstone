import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

class StartNewProjectScreen extends StatefulWidget {
  const StartNewProjectScreen({super.key});

  @override
  State<StartNewProjectScreen> createState() => _StartNewProjectScreenState();
}

class _StartNewProjectScreenState extends State<StartNewProjectScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _courseNameController = TextEditingController();
  DateTime? _deadline;
  List<String> _selectedUsers = [];
  List<Map<String, String>> _userList = [];

  @override
  void initState() {
    super.initState();
    final db = MockDatabase();
    final role = db.getUserRole(db.currentLoggedInUser ?? '');
    if (role != 'teacher') {
      Future.microtask(() => _showUnauthorized());
    } else {
      _userList = db
          .getAllUsers()
          .where((u) => u['username'] != 'admin')
          .map((u) => {
                'username': u['username'].toString(),
                'role': u['role'].toString(),
              })
          .toList();

    }
  }

  void _showUnauthorized() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: const Text('Only teachers are allowed to start a new project.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }

  void _submitProject() {
    final name = _nameController.text.trim();
    final courseName = _courseNameController.text.trim();
    final db = MockDatabase();
    final currentUser = db.currentLoggedInUser ?? '';
    final formattedDeadline = _deadline?.toIso8601String();

    if (name.isEmpty || courseName.isEmpty || formattedDeadline == null || _selectedUsers.isEmpty) {
      _showError('All fields and at least one member are required.');
      return;
    }

    // Add current teacher to the members list
    if (!_selectedUsers.contains(currentUser)) {
      _selectedUsers.add(currentUser);
    }

    db.addProject({
      'name': name,
      'course': courseName,
      'startDate': DateTime.now().toIso8601String(),
      'deadline': formattedDeadline,
      'members': _selectedUsers.join(','),
    });

    Navigator.pop(context);
  }


  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Input Error'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.blueText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Start Your Project',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.blueText,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputField(_nameController, 'Group Name'),
            const SizedBox(height: 16),
            _buildInputField(_courseNameController, 'Course Name'),
            const SizedBox(height: 16),
            Text(
              'Add Members to this Project:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.blueText),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: null,
              decoration: InputDecoration(
                hintText: 'Select a member to add',
                filled: true,
                fillColor: Colors.blue[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _userList
                  .where((user) => !_selectedUsers.contains(user['username']))
                  .map((user) => DropdownMenuItem(
                        value: user['username'],
                        child: Text(
                          user['role'] == 'teacher'
                              ? '${user['username']} (teacher)'
                              : user['username']!,
                          style: GoogleFonts.poppins(),
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null && !_selectedUsers.contains(value)) {
                  setState(() => _selectedUsers.add(value));
                }
              },
            ),
            Wrap(
              spacing: 8,
              children: _selectedUsers.map((user) {
                final role = _userList.firstWhere((u) => u['username'] == user)['role'];
                return Chip(
                  label: Text(role == 'teacher' ? '$user (teacher)' : user),
                  onDeleted: () => setState(() => _selectedUsers.remove(user)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.blueText),
                const SizedBox(width: 12),
                Text(
                  _deadline != null
                      ? 'Deadline: ${_deadline!.toLocal().toString().split(' ')[0]}'
                      : 'Pick Project Deadline',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.date_range, color: AppColors.blueText),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _deadline = picked);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueText,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'CONFIRM',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hintText) {
    return TextField(
      controller: controller,
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
