// manage_courses_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mock_database.dart';
import 'app_colors.dart';

extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class ManageCoursesScreen extends StatefulWidget {
  /// If true returns content-only (no Scaffold/AppBar) so it can be embedded
  /// inside MainDashboard's chrome. Otherwise acts as a standalone route.
  final bool embedded;

  /// Optional callback invoked when courses list changes (add/delete/rename).
  final VoidCallback? onCoursesChanged;

  const ManageCoursesScreen({
    super.key,
    this.embedded = false,
    this.onCoursesChanged,
  });

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  final db = MockDatabase();

  // ---------- constants ----------
  static const List<String> _semesterDisplayOptions = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
  ];

  // RMIT campuses (short list; expand if you need more)
  static const List<String> _campusOptions = [
    'Saigon South',
    'Hanoi',
    'Melbourne City',
    'Bundoora',
    'Brunswick',
    'Europe (Barcelona)',
  ];

  // ---------- search ----------
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------- styles ----------
  ElevatedButtonThemeData get _elevatedBtnTheme => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.button,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  TextButtonThemeData get _textBtnTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.button,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      );

  OutlinedButtonThemeData get _outlinedBtnTheme => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.button,
          side: BorderSide(color: AppColors.button, width: 1.2),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE9F0FF);
    final hintColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: hintColor),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  // ---------------------------
  // Helpers
  // ---------------------------

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          elevatedButtonTheme: _elevatedBtnTheme,
          textButtonTheme: _textBtnTheme,
          outlinedButtonTheme: _outlinedBtnTheme,
        ),
        child: AlertDialog(
          title: Text(
            'Error',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Text(msg, style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              child: Text('OK', style: GoogleFonts.poppins()),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  /// Determines if a course (year + semester) has already **ended**.
  ///
  /// Semesters:
  /// - S1: Feb → May (same calendar year)
  /// - S2: Jun → Sep (same calendar year)
  /// - S3: Oct → Jan (**next** calendar year)
  bool _isPastCourseYearSem(String year, String semCode) {
    final now = DateTime.now();
    final y = int.tryParse(year);
    if (y == null) return false;

    int endYear, endMonth;
    switch (semCode.toUpperCase()) {
      case 'S1':
        endYear = y;
        endMonth = 5; // May
        break;
      case 'S2':
        endYear = y;
        endMonth = 9; // September
        break;
      case 'S3':
        endYear = y + 1; // crosses into next year
        endMonth = 1; // January
        break;
      default:
        endYear = y;
        endMonth = 12;
    }

    int nextMonth = endMonth + 1;
    int nextMonthYear = endYear;
    if (nextMonth == 13) {
      nextMonth = 1;
      nextMonthYear += 1;
    }
    final endInstant =
        DateTime(nextMonthYear, nextMonth, 1).subtract(const Duration(milliseconds: 1));

    return now.isAfter(endInstant);
  }

  /// NEW: has this semester **started** yet? (If yes, creation is blocked.)
  ///
  /// Starts: S1 = Feb 1 (y), S2 = Jun 1 (y), S3 = Oct 1 (y).
  bool _hasCourseSemesterStarted(String year, String semCode) {
    final y = int.tryParse(year);
    if (y == null) return false;

    int startMonth;
    switch (semCode.toUpperCase()) {
      case 'S1':
        startMonth = 2; // Feb
        break;
      case 'S2':
        startMonth = 6; // Jun
        break;
      case 'S3':
        startMonth = 10; // Oct
        break;
      default:
        return false;
    }

    final start = DateTime(y, startMonth, 1);
    final now = DateTime.now();
    return now.isAfter(start) || now.isAtSameMomentAs(start);
  }

  Future<bool> _confirm(String title, String message) async {
    return (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            content: Text(message, style: GoogleFonts.poppins()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.button),
                child: Text('Confirm', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        )) ??
        false;
  }

  Widget _buildInput(TextEditingController controller, String hint, {int maxLines = 1}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(color: onSurface),
      decoration: _inputDecoration(context, hint),
    );
  }

  Widget _buildDropdownField({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      items: items
          .map((s) => DropdownMenuItem<String>(
                value: s,
                child: Text(s, style: GoogleFonts.poppins(color: onSurface)),
              ))
          .toList(),
      onChanged: onChanged,
      style: GoogleFonts.poppins(color: onSurface),
      decoration: _inputDecoration(context, hint),
      dropdownColor: isDark ? const Color(0xFF2B2B2B) : Colors.white,
      iconEnabledColor: onSurface,
    );
  }

  Widget _buildSearchField() {
    final theme = Theme.of(context);
    final fill = theme.brightness == Brightness.dark
        ? Colors.grey[850]
        : theme.colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.poppins(),
        decoration: InputDecoration(
          hintText: 'Search courses...',
          hintStyle: GoogleFonts.poppins(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          filled: true,
          fillColor: fill,
          prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  color: theme.iconTheme.color,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  // Extract "COSC1234" from "COSC1234 - Engineering"
  String _prefixIdFromName(String fullName) {
    final parts = fullName.split(RegExp(r'\s\-\s'));
    return parts.isNotEmpty ? parts[0].trim() : fullName.trim();
  }

  // Semester display <-> code
  String _semCodeFromDisplay(String display) {
    switch (display.trim().toLowerCase()) {
      case 'semester 1':
        return 'S1';
      case 'semester 2':
        return 'S2';
      case 'semester 3':
        return 'S3';
      default:
        return '';
    }
  }

  String _semDisplayFromCode(String code) {
    switch (code.trim().toUpperCase()) {
      case 'S1':
        return 'Semester 1';
      case 'S2':
        return 'Semester 2';
      case 'S3':
        return 'Semester 3';
      default:
        return code;
    }
  }

  // Parse "2025 S1" or "S1 2025" into {year, sem}
  Map<String, String> _splitYearSem(String raw) {
    final s = raw.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final m =
        RegExp(r'(?:(\d{4})\s+(S[123]))|(?:(S[123])\s+(\d{4}))').firstMatch(s);
    if (m == null) return {'year': '', 'sem': ''};
    final year = m.group(1) ?? m.group(4) ?? '';
    final sem = (m.group(2) ?? m.group(3) ?? '').toUpperCase();
    return {'year': year, 'sem': sem};
  }

  // Conflict if another course has same (prefix+id, year, sem, campus)
  bool _existsCourseConflict({
    required String prefix,
    required String id,
    required String year,
    required String semCode, // S1/S2/S3
    required String campus, // compare too
    String? excludeCourseId,
  }) {
    final pid = (prefix + id).toUpperCase();
    final campusNorm = campus.trim().toLowerCase();

    for (final c in db.getAllCoursesRich()) {
      if (excludeCourseId != null &&
          (c['id'] ?? '').toString() == excludeCourseId) {
        continue;
      }

      final existingPid =
          _prefixIdFromName((c['name'] ?? '').toString()).toUpperCase();

      final ys = _splitYearSem((c['semester'] ?? '').toString());
      final existingYear = (ys['year'] ?? '').trim();
      final existingSem = (ys['sem'] ?? '').trim().toUpperCase();

      final existingCampusNorm =
          (c['campus'] ?? '').toString().trim().toLowerCase();

      if (existingPid == pid &&
          existingYear == year &&
          existingSem == semCode &&
          existingCampusNorm == campusNorm) {
        return true;
      }
    }
    return false;
  }

  // ---------------------------
  // Member pickers (for admin/teacher)
  // ---------------------------

  Future<List<String>> _pickUsers({
    required List<String> initial,
    required String roleFilter, // 'teacher' for lecturers, 'user' for students
    required String title,
  }) async {
    final all = db
        .getAllUsers()
        .where((u) => (u['role'] ?? '') == roleFilter)
        .map((u) => u['username'].toString())
        .toList();

    final selected = initial.toSet();
    final searchCtl = TextEditingController();
    String localQuery = '';

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return Theme(
          data: Theme.of(context).copyWith(
            elevatedButtonTheme: _elevatedBtnTheme,
            textButtonTheme: _textBtnTheme,
            outlinedButtonTheme: _outlinedBtnTheme,
            checkboxTheme: CheckboxThemeData(
              fillColor: MaterialStateProperty.all(AppColors.button),
              checkColor: MaterialStateProperty.all(Colors.white),
            ),
          ),
          child: StatefulBuilder(builder: (context, setSheet) {
            final filtered = all
                .where((u) =>
                    u.toLowerCase().contains(localQuery.toLowerCase()))
                .toList();
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchCtl,
                      style: GoogleFonts.poppins(),
                      decoration: _inputDecoration(context, 'Search usernames...')
                          .copyWith(prefixIcon: const Icon(Icons.search)),
                      onChanged: (v) => setSheet(() => localQuery = v),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final username = filtered[i];
                          final checked = selected.contains(username);
                          final full = db.getFullNameByUsername(username);
                          return CheckboxListTile(
                            value: checked,
                            controlAffinity: ListTileControlAffinity.trailing,
                            activeColor: AppColors.button,
                            checkColor: Colors.white,
                            title: Text(
                              full?.isNotEmpty == true
                                  ? '$full (@$username)'
                                  : username,
                              style: GoogleFonts.poppins(),
                            ),
                            onChanged: (_) {
                              setSheet(() {
                                if (checked) {
                                  selected.remove(username);
                                } else {
                                  selected.add(username);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pop(context, selected.toList()),
                        icon: const Icon(Icons.check),
                        label: Text('Done', style: GoogleFonts.poppins()),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );

    return result ?? initial;
  }

  Widget _chips(String label, List<String> users, {VoidCallback? onEdit}) {
    final theme = Theme.of(context);
    final chipBg = theme.brightness == Brightness.dark
        ? AppColors.blueText.withOpacity(0.12)
        : AppColors.blueText.withOpacity(0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            if (onEdit != null)
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: Text('Edit', style: GoogleFonts.poppins()),
              ),
          ],
        ),
        Wrap(
          spacing: 6,
          runSpacing: -8,
          children: (users.isEmpty
                  ? [
                      Chip(
                        label: Text(
                          'None',
                          style: GoogleFonts.poppins(
                              color: theme.disabledColor),
                        ),
                        backgroundColor: chipBg,
                      )
                    ]
                  : users.map((u) {
                      final full = db.getFullNameByUsername(u);
                      final text = full?.isNotEmpty == true
                          ? '$full (@$u)'
                          : u;
                      return Chip(
                        label: Text(text, style: GoogleFonts.poppins()),
                        backgroundColor: chipBg,
                      );
                    }))
              .toList(),
        ),
      ],
    );
  }

  // ---------------------------
  // Add Course (dialog)
  // ---------------------------

  void _openAddCourseDialog() {
    final TextEditingController prefixCtl = TextEditingController();
    final TextEditingController idCtl = TextEditingController();
    final TextEditingController nameCtl = TextEditingController();
    final TextEditingController yearCtl = TextEditingController();
    final TextEditingController descCtl = TextEditingController();

    String? semDisplay;
    String? campus;
    List<String> lecturers = [];
    List<String> students = [];

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final onSurface = isDark ? Colors.white : const Color(0xFF1F2450);
        
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
              surface: surface,
              onSurface: onSurface,
            ),
            elevatedButtonTheme: _elevatedBtnTheme,
            textButtonTheme: _textBtnTheme,
            outlinedButtonTheme: _outlinedBtnTheme,
            dialogTheme: DialogThemeData(backgroundColor: surface),
          ),
          child: StatefulBuilder(builder: (ctx, setDlg) {
            return AlertDialog(
              backgroundColor: surface,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Add Course',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInput(prefixCtl, 'Prefix (e.g. COSC)'),
                    const SizedBox(height: 8),
                    _buildInput(idCtl, 'ID (e.g. 1234)'),
                    const SizedBox(height: 8),
                    _buildInput(nameCtl, 'Course Name (e.g. Engineering)'),
                    const SizedBox(height: 8),
                    _buildInput(yearCtl, 'Year (e.g. 2025)'),
                    const SizedBox(height: 8),
                    _buildDropdownField(
                      hint: 'Semester',
                      value: semDisplay,
                      items: _semesterDisplayOptions,
                      onChanged: (v) => setDlg(() => semDisplay = v),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdownField(
                      hint: 'Campus',
                      value: campus,
                      items: _campusOptions,
                      onChanged: (v) => setDlg(() => campus = v),
                    ),
                    const SizedBox(height: 8),
                    _buildInput(descCtl, 'Description', maxLines: 3),
                    const SizedBox(height: 12),
                    _chips('Lecturers (for new course)', lecturers,
                        onEdit: () async {
                      final picked = await _pickUsers(
                        initial: lecturers,
                        roleFilter: 'teacher',
                        title: 'Select Lecturers',
                      );
                      setDlg(() => lecturers = picked);
                    }),
                    const SizedBox(height: 8),
                    _chips('Students (for new course)', students,
                        onEdit: () async {
                      final picked = await _pickUsers(
                        initial: students,
                        roleFilter: 'user',
                        title: 'Select Students',
                      );
                      setDlg(() => students = picked);
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final prefix = prefixCtl.text.trim().toUpperCase();
                    final id = idCtl.text.trim();
                    final name = nameCtl.text.trim().toTitleCase();
                    final year = yearCtl.text.trim();
                    final semCode = _semCodeFromDisplay(semDisplay ?? '');
                    final cam = (campus ?? '').trim();
                    final desc = descCtl.text.trim();

                    if ([prefix, id, name, year, semCode, cam, desc]
                        .any((s) => s.isEmpty)) {
                      _showError(
                          'Please fill in all fields: Prefix, ID, Course Name, Year, Semester, Campus, Description.');
                      return;
                    }
                    if (!RegExp(r'^\d{4}$').hasMatch(year)) {
                      _showError('Year must be 4 digits (e.g. 2025).');
                      return;
                    }

                    // NEW RULE: Only allow creating BEFORE the semester starts.
                    if (_hasCourseSemesterStarted(year, semCode)) {
                      _showError('You can only create a course before the semester starts.');
                      return;
                    }

                    final semesterDisplay = '$year $semCode';
                    if (_existsCourseConflict(
                      prefix: prefix,
                      id: id,
                      year: year,
                      semCode: semCode,
                      campus: cam,
                    )) {
                      _showError(
                          'A course with this Prefix & ID already exists in $semesterDisplay at $cam.');
                      return;
                    }

                    final ok = await _confirm(
                      'Create Course',
                      'Create $prefix$id – $name for $semesterDisplay at $cam?',
                    );
                    if (!ok) return;

                    db.createCourse(
                      name: '$prefix$id - $name',
                      semester: semesterDisplay,
                      campus: cam,
                      lecturers: lecturers,
                      students: students,
                      description: desc,
                    );

                    Navigator.of(ctx).pop();
                    setState(() {});
                    widget.onCoursesChanged?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Course added successfully')),
                    );
                  },
                  child: Text('Save', style: GoogleFonts.poppins()),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  // ---------------------------
  // Delete / Edit
  // ---------------------------

  void _deleteCourse(Map<String, dynamic> course) {
    final courseName = (course['name'] ?? '').toString();
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          elevatedButtonTheme: _elevatedBtnTheme,
          textButtonTheme: _textBtnTheme,
        ),
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              Text('Delete Course',
                  style:
                      GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ],
          ),
          content: Text(
            'Are you sure you want to delete the course "$courseName"? '
            'This will also remove it from all associated projects.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () {
                db.deleteCourseById(course['id'].toString());
                setState(() {});
                widget.onCoursesChanged?.call();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Course deleted')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child:
                  Text('Confirm', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _modifyCourse(Map<String, dynamic> course) {
    final rootCtx = context;

    final oldCourseName = (course['name'] ?? '').toString();
    final parts = oldCourseName.split(RegExp(r'\s\-\s'));
    final prefixAndId = parts.isNotEmpty ? parts[0].trim() : '';
    final namePart = parts.length > 1 ? parts[1].trim() : '';

    final idMatch = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(prefixAndId);
    final prefix = idMatch?.group(1) ?? '';
    final numId = idMatch?.group(2) ?? '';

    final ys = _splitYearSem((course['semester'] ?? '').toString());
    final initialSemDisplay = _semDisplayFromCode(ys['sem'] ?? '');

    final TextEditingController newPrefix =
        TextEditingController(text: prefix);
    final TextEditingController newId = TextEditingController(text: numId);
    final TextEditingController newName =
        TextEditingController(text: namePart);
    final TextEditingController newYear =
        TextEditingController(text: (ys['year'] ?? ''));
    String localSemDisplay = initialSemDisplay;
    String localCampus = (course['campus'] ?? '').toString();
    final TextEditingController newDesc = TextEditingController(
        text: (course['description'] ?? '').toString());

    List<String> lecturers =
        List<String>.from(course['lecturers'] ?? const []);
    List<String> students =
        List<String>.from(course['students'] ?? const []);

    showDialog(
      context: rootCtx,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final onSurface = isDark ? Colors.white : const Color(0xFF1F2450);

        return Theme(
          data: Theme.of(dialogCtx).copyWith(
            colorScheme: Theme.of(dialogCtx).colorScheme.copyWith(
              surface: surface,
              onSurface: onSurface,
            ),
            elevatedButtonTheme: _elevatedBtnTheme,
            textButtonTheme: _textBtnTheme,
            outlinedButtonTheme: _outlinedBtnTheme,
            dialogTheme: DialogThemeData(backgroundColor: surface),
          ),
          child: StatefulBuilder(builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: surface,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Edit Course',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInput(newPrefix, 'Prefix'),
                    const SizedBox(height: 8),
                    _buildInput(newId, 'ID'),
                    const SizedBox(height: 8),
                    _buildInput(newName, 'Name'),
                    const SizedBox(height: 8),
                    _buildInput(newYear, 'Year (e.g. 2025)'),
                    const SizedBox(height: 8),
                    _buildDropdownField(
                      hint: 'Semester',
                      value:
                          localSemDisplay.isEmpty ? null : localSemDisplay,
                      items: _semesterDisplayOptions,
                      onChanged: (v) =>
                          setDialogState(() => localSemDisplay = v ?? ''),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdownField(
                      hint: 'Campus',
                      value: localCampus.isEmpty ? null : localCampus,
                      items: _campusOptions,
                      onChanged: (v) =>
                          setDialogState(() => localCampus = v ?? ''),
                    ),
                    const SizedBox(height: 8),
                    _buildInput(newDesc, 'Description', maxLines: 3),
                    const SizedBox(height: 12),
                    _chips('Lecturers', lecturers, onEdit: () async {
                      final picked = await _pickUsers(
                        initial: lecturers,
                        roleFilter: 'teacher',
                        title: 'Select Lecturers',
                      );
                      setDialogState(() => lecturers = picked);
                    }),
                    const SizedBox(height: 8),
                    _chips('Students', students, onEdit: () async {
                      final picked = await _pickUsers(
                        initial: students,
                        roleFilter: 'user',
                        title: 'Select Students',
                      );
                      setDialogState(() => students = picked);
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final p = newPrefix.text.trim().toUpperCase();
                    final i = newId.text.trim();
                    final n = newName.text.trim().toTitleCase();
                    final yr = newYear.text.trim();
                    final semCode = _semCodeFromDisplay(localSemDisplay);
                    final cam = localCampus.trim();
                    final des = newDesc.text.trim();

                    if ([p, i, n, yr, semCode, cam, des]
                        .any((s) => s.isEmpty)) {
                      _showError(
                          'All fields are required: Prefix, ID, Name, Year, Semester, Campus, Description.');
                      return;
                    }
                    if (!RegExp(r'^\d{4}$').hasMatch(yr)) {
                      _showError('Year must be 4 digits (e.g. 2025).');
                      return;
                    }

                    // Keep past-course guard for edits.
                    if (_isPastCourseYearSem(yr, semCode)) {
                      _showError('Cannot save a course in the past.');
                      return;
                    }

                    final newFullName = '$p$i - $n';
                    final semesterDisplay = '$yr $semCode';

                    if (_existsCourseConflict(
                      prefix: p,
                      id: i,
                      year: yr,
                      semCode: semCode,
                      campus: cam,
                      excludeCourseId: course['id'].toString(),
                    )) {
                      _showError(
                          'A course with this Prefix & ID already exists in $semesterDisplay at $cam.');
                      return;
                    }

                    final ok = await _confirm(
                      'Save Changes',
                      'Update $p$i – $n to $semesterDisplay at $cam?',
                    );
                    if (!ok) return;

                    db.updateCourse(
                      course['id'].toString(),
                      name: newFullName,
                      semester: semesterDisplay,
                      campus: cam,
                      description: des,
                      lecturers: lecturers,
                      students: students,
                    );

                    Navigator.of(dialogCtx).pop();
                    setState(() {});
                    widget.onCoursesChanged?.call();
                    ScaffoldMessenger.of(rootCtx).showSnackBar(
                        const SnackBar(content: Text('Course updated')));
                  },
                  child: Text('Save', style: GoogleFonts.poppins()),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  // ---------------------------
  // UI
  // ---------------------------

  @override
  Widget build(BuildContext context) {
    final rich = db.getAllCoursesRich();
    final filtered = rich
        .where((c) => (c['name'] ?? '')
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) =>
          (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final listOnly = Theme(
      data: theme.copyWith(
        elevatedButtonTheme: _elevatedBtnTheme,
        textButtonTheme: _textBtnTheme,
        outlinedButtonTheme: _outlinedBtnTheme,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.embedded) _buildSearchField(),
              if (filtered.isEmpty)
                Center(
                  child: Text(
                    'No courses found.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                )
              else
                ListView.builder(
                  itemCount: filtered.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final course = filtered[index];
                    final name = (course['name'] ?? '').toString();
                    final semRaw = (course['semester'] ?? 'N/A').toString();
                    final campus = (course['campus'] ?? 'N/A').toString();
                    final lCount = (course['lecturers'] as List?)?.length ?? 0;
                    final sCount = (course['students'] as List?)?.length ?? 0;

                    final ys = _splitYearSem(semRaw);
                    final yr = ys['year'] ?? '';
                    final smCode = ys['sem'] ?? '';
                    final smDisplay = _semDisplayFromCode(smCode);

                    return Card(
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          name,
                          style: GoogleFonts.poppins(
                            color: onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Year: $yr • Semester: $smDisplay • Campus: $campus\n'
                            'Lecturers: $lCount • Students: $sCount',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            Tooltip(
                              message: 'Edit Course Info',
                              child: IconButton(
                                icon: Icon(Icons.edit, color: onSurface),
                                onPressed: () => _modifyCourse(course),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCourse(course),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              SizedBox(height: widget.embedded ? kBottomNavigationBarHeight : 0),
            ],
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return Stack(
        children: [
          listOnly,
          Positioned(
            right: 16,
            bottom: kBottomNavigationBarHeight + 16,
            child: FloatingActionButton.extended(
              onPressed: _openAddCourseDialog,
              icon: const Icon(Icons.add),
              label: Text('Add Course', style: GoogleFonts.poppins()),
              backgroundColor: AppColors.button,
              foregroundColor: Colors.white,
            ),
          )
        ],
      );
    }

    return Theme(
      data: theme.copyWith(
        elevatedButtonTheme: _elevatedBtnTheme,
        textButtonTheme: _textBtnTheme,
        outlinedButtonTheme: _outlinedBtnTheme,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(color: onSurface),
          title: Text(
            'Manage Courses',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: _buildSearchField(),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddCourseDialog,
          icon: const Icon(Icons.add),
          label: Text('Add Course', style: GoogleFonts.poppins()),
          backgroundColor: AppColors.button,
          foregroundColor: Colors.white,
        ),
        body: listOnly,
      ),
    );
  }
}
