import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
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
  List<String> _selectedUsers = [];
  List<Map<String, String>> _userList = [];
  List<MultiSelectItem<String>> _userItems = [];
  String? _selectedCourse;
  List<String> _availableCourses = [];

  @override
  void initState() {
    super.initState();
    final db = MockDatabase();
    final role = db.getUserRole(db.currentLoggedInUser ?? '');
    if (role != 'teacher' && role != 'admin' && role != 'officer') {
      Future.microtask(() => _showUnauthorized());
    } else {
      _userList = db
          .getAllUsers()
          .where((u) =>
              u['username'] != 'admin' &&
              u['role'] != 'admin' &&
              u['role'] != 'officer')
          .map((u) => {
                'username': u['username'].toString(),
                'fullName': (u['fullName'] ?? u['username']).toString(),
                'role': u['role'].toString(),
              })
          .toList();
      _userItems = _userList.map((user) {
        final display = user['role'] == 'teacher'
            ? '${user['fullName']} (teacher)'
            : user['fullName'] ?? user['username']!;
        return MultiSelectItem<String>(user['username']!, display);
      }).toList();
      _availableCourses = db.getCourses();
    }
  }

  void _showUnauthorized() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: const Text('Only teachers and admins are allowed to start a new project.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }

  void _confirmSubmitProject() async {
    final name = _nameController.text.trim();
    final formattedDeadline = _deadline?.toIso8601String();

    if (name.isEmpty || _selectedCourse == null || formattedDeadline == null || _selectedUsers.isEmpty) {
      _showError('All fields and at least one member are required.');
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueText),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _submitProject();
    }
  }

  void _submitProject() {
    final name = _nameController.text.trim();
    final db = MockDatabase();
    final currentUser = db.currentLoggedInUser ?? '';
    final formattedDeadline = _deadline?.toIso8601String();

    if (!_selectedUsers.contains(currentUser)) {
      final role = db.getUserRole(currentUser);
      if (role == 'teacher') {
        _selectedUsers.add(currentUser);
      }
    }

    db.addProject({
      'name': name,
      'course': _selectedCourse!,
      'startDate': DateTime.now().toIso8601String(),
      'deadline': formattedDeadline!,
      'members': _selectedUsers.join(','),
    });

    Navigator.pop(context, true);
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

  Future<void> _pickDeadline() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _deadline = fullDateTime;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // theme-aware colors so text is readable in dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final inputFill = isDark ? Colors.grey[800] : Colors.blue[50];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Start Your Project',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputField(context, _nameController, 'Group Name'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: 'Select Course',
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              value: _selectedCourse,
              style: TextStyle(color: primaryText),
              items: _availableCourses
                  .map((course) => DropdownMenuItem(
                        value: course,
                        child: Text(course, style: TextStyle(color: primaryText)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCourse = value),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Members to this Project:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: primaryText),
            ),
            const SizedBox(height: 8),
            MultiSelectDialogField<String>(
              items: _userItems,
              title: const Text("Select Members"),
              selectedColor: AppColors.blueText,
              decoration: BoxDecoration(
                color: inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.transparent),
              ),
              buttonIcon: Icon(Icons.person_add, color: primaryText),
              buttonText: Text(
                "Select members to add",
                style: GoogleFonts.poppins(color: primaryText),
              ),
              onConfirm: (values) {
                setState(() => _selectedUsers = values);
              },
              chipDisplay: MultiSelectChipDisplay(
                items: _selectedUsers.map((e) {
                  final role = _userList.firstWhere((u) => u['username'] == e)['role'];
                  final label = role == 'teacher' ? '$e (teacher)' : e;
                  return MultiSelectItem<String>(e, label);
                }).toList(),
                onTap: (value) {
                  setState(() => _selectedUsers.remove(value));
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
                    _deadline != null
                        ? 'Deadline: ${_deadline!.toLocal().toString().substring(0, 16)}'
                        : 'Pick Project Deadline',
                    style: GoogleFonts.poppins(fontSize: 16, color: primaryText),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.date_range, color: primaryText),
                  onPressed: _pickDeadline,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _confirmSubmitProject,
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

  // NOTE: changed to accept BuildContext so we can use theme colors here.
  Widget _buildInputField(BuildContext context, TextEditingController controller, String hintText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final inputFill = isDark ? Colors.grey[800] : Colors.blue[50];

    return TextField(
      controller: controller,
      style: TextStyle(color: primaryText),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: primaryText?.withOpacity(0.6)),
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
