// edit_project_screen.dart (improved, supports embedded mode)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:intl/intl.dart';
import 'mock_database.dart';

class EditProjectScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  /// If true the widget returns content-only (no Scaffold/AppBar) so it can
  /// be embedded inside MainDashboard's IndexedStack and keep the global chrome.
  final bool embedded;

  /// Optional callback invoked after a successful save (useful in embedded mode).
  final VoidCallback? onSaved;

  const EditProjectScreen({
    super.key,
    required this.project,
    this.embedded = false,
    this.onSaved,
  });

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final MockDatabase db = MockDatabase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late DateTime _deadline;
  String? _selectedCourse;
  List<String> _selectedMembers = [];

  late List<Map<String, dynamic>> allStudents;
  late List<String> availableCourses;

  @override
  void initState() {
    super.initState();

    final role = db.getUserRole(db.currentLoggedInUser ?? '');
    if (role != 'teacher' && role != 'admin' && role != 'officer') {
      // show an error and navigate back to safe route (runs after frame)
      Future.microtask(() => _showUnauthorized());
    }

    _nameController = TextEditingController(text: widget.project['name']?.toString() ?? '');
    _selectedCourse = widget.project['course']?.toString();
    _deadline = DateTime.tryParse(widget.project['deadline']?.toString() ?? '') ?? DateTime.now();

    final rawMembers = widget.project['members'];
    _selectedMembers = rawMembers is String
        ? rawMembers.split(',').map((id) => id.trim()).where((id) => id.isNotEmpty).toList()
        : (rawMembers is List ? List<String>.from(rawMembers.map((e) => e.toString())) : <String>[]);

    // Filter only non-admin/non-officer users (students/teachers)
    allStudents = db.getAllUsers().where((user) {
      final r = user['role']?.toString() ?? '';
      return r != 'admin' && r != 'officer';
    }).toList();

    // ensure we have a safe list of available courses
    final rawCourses = db.getCourses();
    if (rawCourses == null) {
      availableCourses = <String>[];
    } else if (rawCourses is List<String>) {
      availableCourses = List<String>.from(rawCourses);
    } else {
      availableCourses = List<String>.from((rawCourses as Iterable).map((e) => e.toString()));
    }
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );

    if (pickedTime == null) return;

    setState(() {
      _deadline = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _showUnauthorized() {
    // If embedded, just close the dialog and leave it to the parent to handle closing.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: const Text('Only teachers, officers, and admins are allowed to edit projects.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              // only navigate away automatically when running as a standalone route
              if (!widget.embedded) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSave() async {
    // validate form
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCourse == null || _selectedCourse!.isEmpty) {
      _showError('Please select a course.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Theme.of(context).colorScheme.tertiary),
            const SizedBox(width: 8),
            const Text('Confirm Changes'),
          ],
        ),
        content: const Text('Are you sure you want to save the changes to this project?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
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
    try {
      final index = db.getAllProjects().indexWhere((p) => p['name'] == widget.project['name']);
      if (index == -1) {
        _showError('Could not find the project to update.');
        return;
      }

      // preserve createdAt if present
      final createdAt = widget.project['createdAt'] ?? DateTime.now().toIso8601String();

      // only the fields we intend to update
      final updatedFields = {
        'name': _nameController.text.trim(),
        'course': _selectedCourse,
        'members': _selectedMembers,
        'startDate': widget.project['startDate'] ?? DateTime.now().toIso8601String(),
        'deadline': _deadline.toIso8601String(),
        'status': db.calculateStatus(_deadline.toIso8601String(), 0),
        'createdAt': createdAt,
      };

      // Merge updated fields into the existing project map to avoid losing other keys.
      final existingProject = Map<String, dynamic>.from(db.getAllProjects()[index] ?? {});
      existingProject.addAll(updatedFields);
      db.getAllProjects()[index] = existingProject;

      // Clear project info for users who were in the old project (match by "name")
      for (var user in db.getAllUsers()) {
        final username = user['username']?.toString() ?? '';
        final info = db.getProjectInfoForUser(username);
        if (info != null && (info['name']?.toString() == widget.project['name']?.toString())) {
          db.setProjectInfoForUser(username, {
            'name': 'N/A',
            'completion': '0%',
            'rank': 'Unranked',
            'course': 'N/A',
            'deadline': '',
          });
        }
      }

      // Set project info for newly selected members
      for (final member in _selectedMembers) {
        db.setProjectInfoForUser(member, {
          'name': existingProject['name'],
          'completion': '0%',
          'status': existingProject['status'],
          'course': existingProject['course'],
          'deadline': existingProject['deadline'],
        });
      }

      // feedback + close
      final successMessage = 'Project "${existingProject['name']}" saved.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage), backgroundColor: Colors.green));
      }

      // call optional callback for embedded usage
      widget.onSaved?.call();

      // In embedded mode, do NOT pop routes — let parent decide how/when to hide embedded view.
      if (!widget.embedded) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError('Failed to save project: $e');
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(child: const Text('OK'), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildContent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateLabel = DateFormat('yyyy-MM-dd - HH:mm').format(_deadline.toLocal());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Group Name',
                filled: true,
                fillColor: scheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Group name is required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: availableCourses.contains(_selectedCourse) ? _selectedCourse : null,
              items: availableCourses
                  .map((course) => DropdownMenuItem<String>(
                        value: course,
                        child: Text(course, style: TextStyle(color: scheme.onSurface)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCourse = value),
              decoration: InputDecoration(
                hintText: 'Select Course',
                filled: true,
                fillColor: scheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Please select a course' : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Add Members to this Project:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: scheme.primary),
            ),
            const SizedBox(height: 8),
            MultiSelectDialogField<String>(
              items: allStudents
                  .map((student) {
                    final username = student['username']?.toString() ?? '';
                    final fullname = (student['fullName']?.toString() ?? username);
                    return MultiSelectItem<String>(username, fullname.capitalize());
                  })
                  .toList(),
              initialValue: _selectedMembers,
              title: const Text("Select Members"),
              selectedColor: scheme.primary,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.transparent),
              ),
              buttonIcon: Icon(Icons.person_add, color: scheme.primary),
              buttonText: Text("Select members to add", style: GoogleFonts.poppins(color: scheme.primary)),
              onConfirm: (values) {
                setState(() {
                  _selectedMembers = List<String>.from(values);
                });
              },
              chipDisplay: MultiSelectChipDisplay(
                items: _selectedMembers.map((e) => MultiSelectItem<String>(e, e.capitalize())).toList(),
                onTap: (value) {
                  setState(() => _selectedMembers.remove(value));
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Deadline: $dateLabel',
                    style: GoogleFonts.poppins(fontSize: 16, color: scheme.onSurface),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.date_range, color: scheme.primary),
                  onPressed: _pickDateTime,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _confirmSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Save Changes', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    if (widget.embedded) {
      // content-only mode (no Scaffold/AppBar)
      return content;
    }

    // standalone route mode: provide its own Scaffold and AppBar (backwards compatible)
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: scheme.primary),
        title: Text(
          'Edit Project',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: scheme.primary,
          ),
        ),
      ),
      body: content,
    );
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}
