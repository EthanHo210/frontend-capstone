import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'mock_database.dart';
import 'app_colors.dart';

class EditProjectScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const EditProjectScreen({super.key, required this.project});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  late TextEditingController _nameController;
  late DateTime _deadline;
  String? _selectedCourse;
  List<String> _selectedMembers = [];

  final MockDatabase db = MockDatabase();
  late List<Map<String, dynamic>> allStudents;
  late List<String> availableCourses;

  @override
  void initState() {
    super.initState();
    final role = db.getUserRole(db.currentLoggedInUser ?? '');
    if (role != 'teacher') {
      Future.microtask(() => _showUnauthorized());
    }

    _nameController = TextEditingController(text: widget.project['name']?.toString() ?? '');
    _selectedCourse = widget.project['course']?.toString();
    _deadline = DateTime.tryParse(widget.project['deadline']?.toString() ?? '') ?? DateTime.now();

    final rawMembers = widget.project['members'];
    _selectedMembers = rawMembers is String
        ? rawMembers.split(',').map((id) => id.trim()).where((id) => id.isNotEmpty).toList()
        : List<String>.from(rawMembers ?? []);

    allStudents = db.getAllUsers().where((user) => user['role'] == 'user').toList();
    availableCourses = db.getCourses();
  }

  void _showUnauthorized() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: const Text('Only teachers are allowed to edit projects.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_deadline),
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

  void _confirmSave() async {
    if (_selectedCourse == null || _selectedCourse!.isEmpty) {
      _showError('Please select a course.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.amber),
            SizedBox(width: 8),
            Text('Confirm Changes'),
          ],
        ),
        content: const Text('Are you sure you want to save the changes to this project?'),
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
      _performSave();
    }
  }


  void _performSave() {
    final index = db.getAllProjects().indexWhere((p) => p['name'] == widget.project['name']);
    if (index != -1) {
      final updatedProject = {
        'name': _nameController.text,
        'course': _selectedCourse,
        'members': _selectedMembers,
        'startDate': widget.project['startDate'], // keep unchanged
        'deadline': _deadline.toIso8601String(),
        'status': db.calculateStatus(_deadline.toIso8601String(), 0),
      };

      db.getAllProjects()[index] = updatedProject;

      for (var user in db.getAllUsers()) {
        final username = user['username'];
        final info = db.getProjectInfoForUser(username);
        if (info != null && info['project'] == widget.project['name']) {
          db.setProjectInfoForUser(username, {
            'project': 'N/A',
            'contribution': '0%',
            'rank': 'Unranked',
            'course': 'N/A',
            'deadline': '',
          });
        }
      }

      for (final member in _selectedMembers) {
        db.setProjectInfoForUser(member, {
          'project': updatedProject['name'],
          'contribution': '0%',
          'rank': updatedProject['status'],
          'course': updatedProject['course'],
          'deadline': updatedProject['deadline'],
        });
      }

      Navigator.pop(context, true);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          )
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
        leading: const BackButton(color: AppColors.blueText),
        title: Text(
          'Edit Project',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppColors.blueText,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Group Name',
                filled: true,
                fillColor: Colors.blue[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCourse,
              items: availableCourses
                  .map((course) => DropdownMenuItem(value: course, child: Text(course)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCourse = value),
              decoration: InputDecoration(
                hintText: 'Select Course',
                filled: true,
                fillColor: Colors.blue[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Members to this Project:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.blueText),
            ),
            const SizedBox(height: 8),
            MultiSelectDialogField(
              items: allStudents
                  .map((student) =>
                      MultiSelectItem(student['username'], student['username'].toString().capitalize()))
                  .toList(),
              initialValue: _selectedMembers,
              title: const Text("Select Members"),
              selectedColor: AppColors.blueText,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.transparent),
              ),
              buttonIcon: const Icon(Icons.person_add, color: AppColors.blueText),
              buttonText: Text(
                "Select members to add",
                style: GoogleFonts.poppins(color: AppColors.blueText),
              ),
              onConfirm: (values) {
                setState(() {
                  _selectedMembers = List<String>.from(values);
                });
              },
              chipDisplay: MultiSelectChipDisplay(
                items: _selectedMembers
                    .map((e) => MultiSelectItem<String>(e, e.capitalize()))
                    .toList(),
                onTap: (value) {
                  setState(() => _selectedMembers.remove(value));
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.blueText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Deadline: ${_deadline.toLocal().toString().substring(0, 16)}',
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.date_range, color: AppColors.blueText),
                  onPressed: _pickDateTime,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _confirmSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueText,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}
