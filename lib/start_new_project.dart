// start_new_project.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:intl/intl.dart';

import 'mock_database.dart';
import 'app_colors.dart';

class StartNewProjectScreen extends StatefulWidget {
  const StartNewProjectScreen({super.key});

  @override
  State<StartNewProjectScreen> createState() => _StartNewProjectScreenState();
}

class _StartNewProjectScreenState extends State<StartNewProjectScreen> {
  final TextEditingController _nameController = TextEditingController();

  DateTime? _deadline;
  String? _selectedCourse;

  final List<String> _selectedUsers = [];
  late final List<Map<String, String>> _userList;
  late final List<MultiSelectItem<String>> _userItems;
  late final List<String> _availableCourses;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final db = MockDatabase();
    final role = db.getUserRole(db.currentLoggedInUser ?? '');

    // Gate access: allow teacher/admin/officer
    if (role != 'teacher' && role != 'admin' && role != 'officer') {
      Future.microtask(_showUnauthorized);
      _userList = const [];
      _userItems = const [];
      _availableCourses = const [];
      return;
    }

    // Build users list (exclude admins & officers from selection)
    _userList = db
        .getAllUsers()
        .where((u) =>
            (u['username'] ?? '') != 'admin' &&
            (u['role'] ?? '') != 'admin' &&
            (u['role'] ?? '') != 'officer')
        .map((u) => {
              'username': (u['username'] ?? '').toString(),
              'fullName': (u['fullName'] ?? u['username'] ?? '').toString(),
              'role': (u['role'] ?? 'user').toString(),
            })
        .toList();

    _userItems = _userList.map((user) {
      final isTeacher = user['role'] == 'teacher';
      final label = isTeacher
          ? '${user['fullName']} (${user['username']}) • teacher'
          : '${user['fullName']} (${user['username']})';
      return MultiSelectItem<String>(user['username']!, label);
    }).toList();

    final coursesRaw = db.getCourses();
    _availableCourses = (coursesRaw is Iterable)
        ? List<String>.from(coursesRaw.map((e) => e.toString()))
        : <String>[];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showUnauthorized() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: const Text(
          'Only teachers, admins, and officers are allowed to start a new project.',
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ).then((_) => Navigator.of(context).maybePop());
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(data: Theme.of(context), child: child!),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(data: Theme.of(context), child: child!),
    );
    if (time == null) return;

    setState(() {
      _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String? _validate() {
    final db = MockDatabase();
    final name = _nameController.text.trim();

    if (name.isEmpty) return 'Please enter a project name.';
    if (_selectedCourse == null || _selectedCourse!.isEmpty) {
      return 'Please select a course.';
    }
    if (_deadline == null) return 'Please pick a deadline.';
    if (_selectedUsers.isEmpty) return 'Please select at least one member.';

    // Unique project name
    final exists = db
        .getAllProjects()
        .any((p) => (p['name'] ?? '').toString().toLowerCase() == name.toLowerCase());
    if (exists) return 'A project with this name already exists.';

    return null;
  }

  Future<void> _confirmSubmitProject() async {
    final error = _validate();
    if (error != null) {
      _showError(error);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.amber),
            SizedBox(width: 8),
            Text('Confirm Project Creation'),
          ],
        ),
        content: const Text('Are you sure you want to create this project?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueText),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) _submitProject();
  }

  void _submitProject() async {
    final db = MockDatabase();

    // currentLoggedInUser can be username OR email → normalize to username
    final id = db.currentLoggedInUser ?? '';
    final currentUsername = db.getUsernameByEmail(id) ?? id; // falls back to id if already a username

    setState(() => _submitting = true);

    try {
      // Ensure teacher creator is included once (if they are a teacher)
      final role = db.getUserRole(id); // accepts username or email
      final members = <String>{
        ..._selectedUsers, // de-dupe
        if (role == 'teacher') currentUsername,
      }.toList();

      db.addProject({
        'name': _nameController.text.trim(),
        'course': _selectedCourse!,
        'startDate': DateTime.now().toIso8601String(),
        'deadline': _deadline!.toIso8601String(),
        'status': 'On-track',
        'createdAt': DateTime.now().toIso8601String(),
        'leader': '',
        'members': members.join(','), // DB expects CSV of usernames
      });

      // NOTE: addProject() now triggers notifications for all members:
      // "You have been added to <Course> - <Project>. Please open the app to check."

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError('Failed to create project: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final inputFill = isDark ? Colors.grey[800] : Colors.blue[50];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: primaryText),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          'Start New Project',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: primaryText),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputField(context, _nameController, 'Project Name'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCourse,
              decoration: InputDecoration(
                hintText: 'Select Course',
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _availableCourses
                  .map((course) => DropdownMenuItem(
                        value: course,
                        child: Text(course, style: TextStyle(color: primaryText)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCourse = value),
            ),
            const SizedBox(height: 16),

            Text('Add Members to this Project:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: primaryText)),
            const SizedBox(height: 8),

            MultiSelectDialogField<String>(
              items: _userItems,
              title: const Text('Select Members'),
              selectedColor: AppColors.blueText,
              decoration: BoxDecoration(
                color: inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.transparent),
              ),
              buttonIcon: Icon(Icons.person_add, color: primaryText),
              buttonText: Text('Select members to add', style: GoogleFonts.poppins(color: primaryText)),
              onConfirm: (values) => setState(() => _selectedUsers
                ..clear()
                ..addAll(values)),
              chipDisplay: MultiSelectChipDisplay(
                items: _selectedUsers.map((username) {
                  final m = _userList.firstWhere(
                    (u) => u['username'] == username,
                    orElse: () => <String, String>{'username': username, 'fullName': username, 'role': 'user'},
                  );
                  final isTeacher = m['role'] == 'teacher';
                  final label = isTeacher
                      ? '${m['fullName']} ($username) • teacher'
                      : '${m['fullName']} ($username)';
                  return MultiSelectItem<String>(username, label);
                }).toList(),
                onTap: (value) {
                  setState(() {
                    _selectedUsers.remove(value);
                  });
                },
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, color: primaryText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _deadline == null
                        ? 'Pick Project Deadline'
                        : 'Deadline: ${DateFormat('yyyy-MM-dd HH:mm').format(_deadline!.toLocal())}',
                    style: GoogleFonts.poppins(fontSize: 16, color: primaryText),
                  ),
                ),
                IconButton(icon: Icon(Icons.date_range, color: primaryText), onPressed: _pickDeadline),
              ],
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _confirmSubmitProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueText,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                _submitting ? 'CREATING…' : 'CONFIRM',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Themed text field helper
  Widget _buildInputField(BuildContext context, TextEditingController controller, String hintText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final inputFill = isDark ? Colors.grey[800] : Colors.blue[50];

    return TextField(
      controller: controller,
      style: TextStyle(color: primaryText),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: primaryText.withOpacity(0.6)),
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
