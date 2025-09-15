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

  /// New + original members (as usernames)
  late List<String> _selectedMembers;
  late List<String> _originalMembers;

  /// All selectable users (username/fullName/role), excluding admin/officer
  late List<Map<String, String>> _allUsers;

  /// Available courses (full names like "COSC1234 - Engineering")
  late List<String> _availableCourses;

  /// Cache current editor role
  late String _editorRole;

  @override
  void initState() {
    super.initState();

    // Gate access
    _editorRole = db.getUserRole(db.currentLoggedInUser ?? '');
    if (_editorRole != 'teacher' && _editorRole != 'admin' && _editorRole != 'officer') {
      Future.microtask(_showUnauthorized);
    }

    _nameController = TextEditingController(text: (widget.project['name'] ?? '').toString());
    _selectedCourse = (widget.project['course'] ?? '').toString();
    _deadline = DateTime.tryParse((widget.project['deadline'] ?? '').toString()) ?? DateTime.now();

    // Parse members from string or list into usernames
    _originalMembers = _parseMemberList(widget.project['members']);
    _selectedMembers = List<String>.from(_originalMembers);

    // Build users list (exclude admin/officer)
    _allUsers = db
        .getAllUsers()
        .where((u) => (u['role'] ?? '') != 'admin' && (u['role'] ?? '') != 'officer')
        .map((u) => {
              'username': (u['username'] ?? '').toString(),
              'fullName': (u['fullName'] ?? u['username'] ?? '').toString(),
              'role': (u['role'] ?? 'user').toString(),
            })
        .toList();

    // Build course list from rich model; teachers see only their courses
    final currentId = db.currentLoggedInUser ?? '';
    final currentUsername = db.getUsernameByEmail(currentId) ?? currentId;

    final rich = db.getAllCoursesRich();
    if (_editorRole == 'teacher') {
      _availableCourses = rich
          .where((c) => _asStringList(c['lecturers']).contains(currentUsername))
          .map((c) => (c['name'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      _availableCourses = rich
          .map((c) => (c['name'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Fallback to legacy list if needed
    if (_availableCourses.isEmpty) {
      final rawCourses = db.getCourses();
      _availableCourses = (rawCourses is Iterable)
          ? rawCourses.map((e) => e.toString()).toList()
          : <String>[];
    }

    // If the current project course isn't in filtered list, still keep it visible (read/edit)
    if (_selectedCourse != null &&
        _selectedCourse!.isNotEmpty &&
        !_availableCourses.contains(_selectedCourse)) {
      _availableCourses = [..._availableCourses, _selectedCourse!];
    }

    // Prune members to the selected course's roster (if any) so the multi-select starts valid.
    _pruneMembersToCourse();
  }

  // ---------- helpers ----------

  List<String> _parseMemberList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) {
      return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  List<String> _asStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  Map<String, dynamic>? _findCourseRichByName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final c in db.getAllCoursesRich()) {
      if ((c['name'] ?? '').toString() == name) return c;
    }
    return null;
  }

  /// Course roster = students + lecturers from the rich course record
  List<Map<String, String>> _courseUserList(String? courseName) {
    final rich = _findCourseRichByName(courseName);
    if (rich == null) return const [];

    final courseStudents = _asStringList(rich['students']).toSet();
    final courseLecturers = _asStringList(rich['lecturers']).toSet();

    final inCourse = <Map<String, String>>[];
    for (final u in _allUsers) {
      final un = u['username']!;
      if (courseStudents.contains(un) || courseLecturers.contains(un)) {
        inCourse.add(u);
      }
    }
    return inCourse;
  }

  List<MultiSelectItem<String>> _buildItemsForCourse(String? courseName) {
    final users = _courseUserList(courseName);
    return users.map((user) {
      final isTeacher = user['role'] == 'teacher';
      final label = isTeacher
          ? '${user['fullName']} (${user['username']}) • teacher'
          : '${user['fullName']} (${user['username']})';
      return MultiSelectItem<String>(user['username']!, label);
    }).toList();
  }

  void _pruneMembersToCourse() {
    final roster = _courseUserList(_selectedCourse).map((u) => u['username']!).toSet();
    setState(() {
      _selectedMembers = _selectedMembers.where(roster.contains).toList();
    });
  }

  bool _hasLecturer(List<String> members) {
    for (final m in members) {
      if (db.getUserRole(m) == 'teacher') return true;
    }
    return false;
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(data: Theme.of(context), child: child!),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
      builder: (ctx, child) => Theme(data: Theme.of(context), child: child!),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: const Text('Only teachers, officers, and admins are allowed to edit projects.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCourse == null || _selectedCourse!.isEmpty) {
      _showError('Please select a course.');
      return;
    }

    // If the editor is not a teacher, ensure at least one lecturer remains on the project.
    if (_editorRole != 'teacher' && !_hasLecturer(_selectedMembers)) {
      _showError('Please include at least one lecturer in the project.');
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
      final projects = db.getAllProjects();
      final idx = projects.indexWhere((p) => p['name'] == widget.project['name']);
      if (idx == -1) {
        _showError('Could not find the project to update.');
        return;
      }

      // Preserve createdAt if present
      final createdAt = widget.project['createdAt'] ?? DateTime.now().toIso8601String();

      // Compute diffs for user project-info updates
      final oldMembers = Set<String>.from(_originalMembers);
      final newMembers = Set<String>.from(_selectedMembers);
      final removed = oldMembers.difference(newMembers);
      final added = newMembers.difference(oldMembers);

      // Update project
      final updated = Map<String, dynamic>.from(projects[idx] ?? {});
      updated.addAll({
        'name': _nameController.text.trim(),
        'course': _selectedCourse,
        // DB expects CSV string for members
        'members': _selectedMembers.join(','),
        'startDate': widget.project['startDate'] ?? DateTime.now().toIso8601String(),
        'deadline': _deadline.toIso8601String(),
        'status': db.calculateStatus(_deadline.toIso8601String(), 0),
        'createdAt': createdAt,
      });
      projects[idx] = updated; // write back

      // Clear project-info for removed members
      for (final username in removed) {
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

      // Set project-info for newly added members
      for (final username in added) {
        db.setProjectInfoForUser(username, {
          'name': updated['name'],
          'completion': '0%',
          'status': updated['status'],
          'course': updated['course'],
          'deadline': updated['deadline'],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project "${updated['name']}" saved.'), backgroundColor: Colors.green),
        );
      }

      widget.onSaved?.call();

      if (!widget.embedded && mounted) {
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

  // ---------- UI ----------

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildContent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateLabel = DateFormat('yyyy-MM-dd - HH:mm').format(_deadline.toLocal());

    final itemsForCourse = _buildItemsForCourse(_selectedCourse);

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

            // Course dropdown (bind with value, not initialValue)
            DropdownButtonFormField<String>(
              value: _availableCourses.contains(_selectedCourse) ? _selectedCourse : null,
              isExpanded: true,
              items: _availableCourses
                  .map((course) => DropdownMenuItem<String>(
                        value: course,
                        child: Text(course, style: TextStyle(color: scheme.onSurface)),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedCourse = value);
                _pruneMembersToCourse();
              },
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

            const SizedBox(height: 12),
            if (_selectedCourse != null && _selectedCourse!.isNotEmpty)
              _CourseRosterSummary(
                course: _findCourseRichByName(_selectedCourse),
                primaryText: scheme.onSurface,
              ),

            const SizedBox(height: 12),

            // Members (course-scoped)
            Text(
              'Members',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: scheme.primary),
            ),
            const SizedBox(height: 8),
            AbsorbPointer(
              absorbing: (_selectedCourse == null || _selectedCourse!.isEmpty),
              child: Opacity(
                opacity: (_selectedCourse == null || _selectedCourse!.isEmpty) ? 0.5 : 1,
                child: MultiSelectDialogField<String>(
                  items: itemsForCourse,
                  initialValue: _selectedMembers.where(
                    (m) => itemsForCourse.any((it) => it.value == m),
                  ).toList(),
                  title: const Text('Select Members'),
                  selectedColor: scheme.primary,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.transparent),
                  ),
                  buttonIcon: Icon(Icons.person_add, color: scheme.primary),
                  buttonText: Text("Select members to add", style: GoogleFonts.poppins(color: scheme.primary)),
                  onConfirm: (values) {
                    setState(() => _selectedMembers
                      ..clear()
                      ..addAll(values));
                  },
                  chipDisplay: MultiSelectChipDisplay(
                    items: _selectedMembers
                        .map((username) {
                          final u = _courseUserList(_selectedCourse).firstWhere(
                                (m) => m['username'] == username,
                                orElse: () => {'username': username, 'fullName': username, 'role': 'user'},
                              );
                          final isTeacher = u['role'] == 'teacher';
                          final label = isTeacher
                              ? '${u['fullName']} ($username) • teacher'
                              : '${u['fullName']} ($username)';
                          return MultiSelectItem<String>(username, label);
                        })
                        .toList(),
                    onTap: (value) => setState(() => _selectedMembers.remove(value)),
                  ),
                ),
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
      return content; // content-only mode
    }

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

class _CourseRosterSummary extends StatelessWidget {
  final Map<String, dynamic>? course;
  final Color primaryText;

  const _CourseRosterSummary({
    required this.course,
    required this.primaryText,
  });

  List<String> _asStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    if (course == null) return const SizedBox.shrink();
    final lecturers = _asStringList(course!['lecturers']);
    final students = _asStringList(course!['students']);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Course roster — Lecturers: ${lecturers.length} • Students: ${students.length}',
        style: GoogleFonts.poppins(color: primaryText),
      ),
    );
  }
}

extension StringCapExt on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}
