// start_new_project.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:intl/intl.dart';

import 'mock_database.dart';
import 'app_colors.dart';

enum AssignmentMode { manual, random }

class StartNewProjectScreen extends StatefulWidget {
  const StartNewProjectScreen({super.key});

  @override
  State<StartNewProjectScreen> createState() => _StartNewProjectScreenState();
}

class _StartNewProjectScreenState extends State<StartNewProjectScreen> {
  final TextEditingController _nameController = TextEditingController();

  DateTime? _deadline;
  String? _selectedCourse; // stores the course full name (e.g., COSC1234 - Engineering)

  // Manual mode selection (usernames)
  final List<String> _selectedUsers = [];

  // Random mode config
  final TextEditingController _randomCountController =
      TextEditingController(text: '5');
  bool _includeCourseLecturers = true;

  // From rich course model; for teachers we filter to only their courses
  // CHANGED: make this mutable (not late final) to avoid LateInitializationError on fallback set.
  List<String> _availableCourses = []; // CHANGED

  bool _submitting = false;
  AssignmentMode _mode = AssignmentMode.manual;

  // Cached: all users except admin/officer (we’ll filter by course on demand)
  // (Mutable for the same reason as above—safe with early returns.)
  List<Map<String, String>> _allUsers = []; // CHANGED

  @override
  void initState() {
    super.initState();
    final db = MockDatabase();

    // Gate access: lecturers (teacher), admins, and officers (to match DB policy).
    final role = db.getUserRole(db.currentLoggedInUser ?? '');
    if (role != 'teacher' && role != 'admin' && role != 'officer') { // CHANGED
      Future.microtask(_showUnauthorized);
      _allUsers = const [];
      _availableCourses = const [];
      return;
    }

    // Build users list (exclude admin/officer from selection)
    _allUsers = db
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

    // Build course list from rich model; fall back to legacy names if needed
    final currentId = db.currentLoggedInUser ?? '';
    final currentUsername = db.getUsernameByEmail(currentId) ?? currentId;

    final rich = db.getAllCoursesRich(); // [{id,name,semester,campus,lecturers,students,...}]
    if (role == 'teacher') {
      _availableCourses = rich
          .where((c) => _asStringList(c['lecturers']).contains(currentUsername))
          .map((c) => (c['name'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      // admin/officer see all
      _availableCourses =
          rich.map((c) => (c['name'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
    }

    // Graceful fallback to legacy list (may assign again → needs mutable field)
    if (_availableCourses.isEmpty) { // CHANGED
      final legacy = db.getCourses();
      _availableCourses = (legacy is Iterable)
          ? List<String>.from(legacy.map((e) => e.toString()))
          : <String>[];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _randomCountController.dispose();
    super.dispose();
  }

  // ----------------- helpers -----------------

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

  Map<String, dynamic>? _findCourseRichByName(String? name) {
    if (name == null || name.isEmpty) return null;
    final db = MockDatabase();
    for (final c in db.getAllCoursesRich()) {
      if ((c['name'] ?? '').toString() == name) return c;
    }
    return null;
  }

  /// Build the course-scoped selectable users list (students + lecturers of the selected course).
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

  void _clearSelectionsOnCourseChange() {
    setState(() {
      _selectedUsers.clear();
      // keep random count / includeLecturers as-is
    });
  }

  void _showUnauthorized() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Access Denied', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Only lecturers, admins, or officers are allowed to start a new project.', // CHANGED
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            child: Text('OK', style: GoogleFonts.poppins()),
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
    final name = _nameController.text.trim();

    if (name.isEmpty) return 'Please enter a project name.';
    if (_selectedCourse == null || _selectedCourse!.isEmpty) {
      return 'Please select a course.';
    }
    if (_deadline == null) return 'Please pick a deadline.';

    if (_mode == AssignmentMode.manual) {
      if (_selectedUsers.isEmpty) return 'Please select at least one member.';
    } else {
      // random mode
      final count = int.tryParse(_randomCountController.text.trim());
      if (count == null || count <= 0) return 'Enter a valid number of students.';
      final course = _findCourseRichByName(_selectedCourse);
      final courseStudents = _asStringList(course?['students']);
      if (count > courseStudents.length) {
        return 'Only ${courseStudents.length} student(s) are available in this course.';
      }
    }

    // NOTE: We removed the global "unique name" constraint here.
    // Duplicate detection (name+course+members) is done right before creation,
    // after we know the exact member set (manual/random).
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
          children: [
            const Icon(Icons.warning, color: Colors.amber),
            const SizedBox(width: 8),
            Text('Confirm Project Creation',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text('Are you sure you want to create this project?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueText),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirm', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) _submitProject();
  }

  List<String> _parseMemberList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) {
      return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  bool _sameMembers(List<String> a, List<String> b) {
    final sa = a.toSet();
    final sb = b.toSet();
    return sa.length == sb.length && sa.containsAll(sb);
  }

  void _submitProject() async {
    final db = MockDatabase();

    // currentLoggedInUser can be username OR email → normalize to username
    final id = db.currentLoggedInUser ?? '';
    final currentUsername = db.getUsernameByEmail(id) ?? id;

    setState(() => _submitting = true);

    final creatorId = db.getUsernameByEmail(db.currentLoggedInUser ?? '') ??
        (db.currentLoggedInUser ?? '');
    final creatorRole = db.getUserRole(creatorId); // accepts username or email

    try {
      // Build final member list based on mode (course-scoped)
      final course = _findCourseRichByName(_selectedCourse);
      final courseStudents = _asStringList(course?['students']);
      final courseLecturers = _asStringList(course?['lecturers']);

      List<String> members;

      if (_mode == AssignmentMode.manual) {
        members = [..._selectedUsers];
      } else {
        // RANDOM: pick N students
        final n = int.parse(_randomCountController.text.trim());
        final rng = Random();
        final pool = [...courseStudents]..shuffle(rng);
        final picked = pool.take(n).toList();

        // optionally include all course lecturers
        final includeLects =
            _includeCourseLecturers ? [...courseLecturers] : <String>[];

        members = {...picked, ...includeLects}.toList();
      }

      // Admin/officer must include at least one lecturer (server enforces too)
      if (creatorRole != 'teacher') {
        final hasLecturer = members.any((u) => db.getUserRole(u) == 'teacher');
        if (!hasLecturer) {
          if (courseLecturers.isNotEmpty) {
            members.add(courseLecturers.first);
          } else {
            setState(() => _submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please add at least one lecturer to the project.',
                  style: GoogleFonts.poppins(),
                ),
              ),
            );
            return;
          }
        }
      }

      // Ensure teacher creator is included once (if they are a teacher)
      members = {
        ...members,
        if (creatorRole == 'teacher') currentUsername,
      }.toList();

      // ---- Duplicate guard (client side) ----  // CHANGED
      final nameLower = _nameController.text.trim().toLowerCase();
      final all = db.getAllProjects();
      for (final p in all) {
        final pName = (p['name'] ?? '').toString().toLowerCase();
        final pCourse = (p['course'] ?? '').toString();
        final pMembers = _parseMemberList(p['members']);
        if (pName == nameLower &&
            pCourse == _selectedCourse &&
            _sameMembers(pMembers, members)) {
          _showError('A project with the same name, course, and members already exists.');
          setState(() => _submitting = false);
          return;
        }
      }
      // ----------------------------------------

      // addProject() enforces canCreateProject() internally (teacher/admin/officer)
      db.addProject({
        'name': _nameController.text.trim(),
        'course': _selectedCourse!, // full course name
        'startDate': DateTime.now().toIso8601String(),
        'deadline': _deadline!.toIso8601String(),
        'status': 'On-track',
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': creatorId,
        'leader': '',
        'members': members.join(','), // DB expects CSV of usernames
      });

      if (!mounted) return;
      Navigator.pop(context, true); // tell caller to refresh
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
        title: Text('Input Error', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            child: Text('OK', style: GoogleFonts.poppins()),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ----------------- UI -----------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText =
        theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final inputFill = isDark ? Colors.grey[800] : Colors.blue[50];

    final itemsForCourse = _buildItemsForCourse(_selectedCourse);

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

            // Select course
            DropdownButtonFormField<String>(
              value: _selectedCourse,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Select Course',
                hintStyle: GoogleFonts.poppins(
                  color: primaryText.withOpacity(0.6),
                ),
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: _availableCourses
                  .map((course) => DropdownMenuItem(
                        value: course,
                        child: Text(course, style: GoogleFonts.poppins(color: primaryText)),
                      ))
                  .toList(),
              onChanged: (value) {
                _selectedCourse = value;
                _clearSelectionsOnCourseChange();
              },
            ),

            const SizedBox(height: 16),

            // Assignment mode selector
            Text('Member Assignment Mode',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: primaryText)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text('Manual', style: GoogleFonts.poppins()),
                  selected: _mode == AssignmentMode.manual,
                  onSelected: (_) => setState(() => _mode = AssignmentMode.manual),
                ),
                ChoiceChip(
                  label: Text('Random', style: GoogleFonts.poppins()),
                  selected: _mode == AssignmentMode.random,
                  onSelected: (_) => setState(() => _mode = AssignmentMode.random),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_selectedCourse != null && _selectedCourse!.isNotEmpty)
              _CourseRosterSummary(
                course: _findCourseRichByName(_selectedCourse),
                primaryText: primaryText,
              ),

            const SizedBox(height: 12),

            // Manual mode: MultiSelect limited to course roster
            if (_mode == AssignmentMode.manual) ...[
              Text('Add Members to this Project:',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: primaryText)),
              const SizedBox(height: 8),
              AbsorbPointer(
                absorbing: (_selectedCourse == null || _selectedCourse!.isEmpty),
                child: Opacity(
                  opacity: (_selectedCourse == null || _selectedCourse!.isEmpty) ? 0.5 : 1,
                  child: MultiSelectDialogField<String>(
                    items: itemsForCourse,
                    title: Text('Select Members', style: GoogleFonts.poppins()),
                    selectedColor: AppColors.blueText,
                    decoration: BoxDecoration(
                      color: inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.transparent),
                    ),
                    buttonIcon: Icon(Icons.person_add, color: primaryText),
                    buttonText: Text('Select members to add',
                        style: GoogleFonts.poppins(color: primaryText)),
                    onConfirm: (values) => setState(() => _selectedUsers
                      ..clear()
                      ..addAll(values)),
                    chipDisplay: MultiSelectChipDisplay(
                      items: _selectedUsers.map((username) {
                        final u = _courseUserList(_selectedCourse).firstWhere(
                              (m) => m['username'] == username,
                              orElse: () => <String, String>{
                                'username': username,
                                'fullName': username,
                                'role': 'user'
                              },
                            );
                        final isTeacher = u['role'] == 'teacher';
                        final label = isTeacher
                            ? '${u['fullName']} ($username) • teacher'
                            : '${u['fullName']} ($username)';
                        return MultiSelectItem<String>(username, label);
                      }).toList(),
                      onTap: (value) {
                        setState(() {
                          _selectedUsers.remove(value);
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],

            // Random mode: count + include lecturers
            if (_mode == AssignmentMode.random) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                        context, _randomCountController, 'Number of students (random)'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: _includeCourseLecturers,
                onChanged: (v) => setState(() => _includeCourseLecturers = v),
                activeColor: AppColors.blueText,
                title: Text('Include all course lecturers',
                    style: GoogleFonts.poppins(color: primaryText)),
                subtitle: Text(
                  'Recommended. Admins/officers must include at least one lecturer.',
                  style: GoogleFonts.poppins(color: primaryText.withOpacity(0.7)),
                ),
              ),
            ],

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

  // Themed text field helper (text)
  Widget _buildInputField(
      BuildContext context, TextEditingController controller, String hintText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final inputFill = isDark ? Colors.grey[800] : Colors.blue[50];

    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(color: primaryText),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(color: primaryText.withOpacity(0.6)),
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Themed numeric field helper (for random count)
  Widget _buildNumberField(
      BuildContext context, TextEditingController controller, String hintText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final inputFill = isDark ? Colors.grey[800] : Colors.blue[50];

    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: GoogleFonts.poppins(color: primaryText),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(color: primaryText.withOpacity(0.6)),
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

// Small roster summary widget (course-scoped)
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
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white10
            : Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Course roster — Lecturers: ${lecturers.length} • Students: ${students.length}',
        style: GoogleFonts.poppins(color: primaryText),
      ),
    );
  }
}
