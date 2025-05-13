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
  late TextEditingController _courseController;
  late DateTime _startDate;
  late DateTime _deadline;
  List<String> _selectedMembers = [];

  final MockDatabase db = MockDatabase();
  late List<Map<String, dynamic>> allStudents;

  @override
  void initState() {
    super.initState();
    final role = db.getUserRole(db.currentLoggedInUser ?? '');
    if (role != 'teacher') {
      Future.microtask(() => _showUnauthorized());
    }

    _nameController = TextEditingController(text: widget.project['name']?.toString() ?? '');
    _courseController = TextEditingController(text: widget.project['course']?.toString() ?? '');
    _startDate = DateTime.tryParse(widget.project['startDate']?.toString() ?? '') ?? DateTime.now();
    _deadline = DateTime.tryParse(widget.project['deadline']?.toString() ?? '') ?? DateTime.now();

    final rawMembers = widget.project['members'];
    _selectedMembers = rawMembers is String
        ? rawMembers.split(',').map((id) => id.trim()).where((id) => id.isNotEmpty).toList()
        : List<String>.from(rawMembers ?? []);

    allStudents = db.getAllUsers().where((user) => user['role'] == 'user').toList();
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

  Future<void> _pickDateTime(bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _deadline;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
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
          if (isStartDate) {
            _startDate = fullDateTime;
          } else {
            _deadline = fullDateTime;
          }
        });
      }
    }
  }

  void _saveChanges() {
    final index = db.getAllProjects().indexWhere((p) => p['name'] == widget.project['name']);
    if (index != -1) {
      final updatedProject = {
        'name': _nameController.text,
        'course': _courseController.text,
        'members': _selectedMembers,
        'startDate': _startDate.toIso8601String(),
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
              decoration: const InputDecoration(labelText: 'Project Name'),
            ),
            TextField(
              controller: _courseController,
              decoration: const InputDecoration(labelText: 'Course'),
            ),
            const SizedBox(height: 16),
            MultiSelectDialogField(
              items: allStudents
                  .map((student) => MultiSelectItem(student['username'], student['username'].toString().capitalize()))
                  .toList(),
              initialValue: _selectedMembers,
              title: const Text("Select Members"),
              buttonText: const Text("Edit Members"),
              searchable: true,
              listType: MultiSelectListType.LIST,
              onConfirm: (values) {
                setState(() {
                  _selectedMembers = List<String>.from(values);
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Start Date"),
              subtitle: Text("${_startDate.toLocal()}".substring(0, 16)),
              trailing: const Icon(Icons.calendar_today, color: AppColors.blueText),
              onTap: () => _pickDateTime(true),
            ),
            ListTile(
              title: const Text("Deadline"),
              subtitle: Text("${_deadline.toLocal()}".substring(0, 16)),
              trailing: const Icon(Icons.calendar_today, color: AppColors.blueText),
              onTap: () => _pickDateTime(false),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueText,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Changes'),
            )
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}
