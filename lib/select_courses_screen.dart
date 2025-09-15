import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
// only for type reference; fine to keep
import 'app_colors.dart';

class SelectCoursesScreen extends StatelessWidget {
  final List<String>? courses;
  final bool embedded;
  final void Function(String courseName)? onCourseTap;

  const SelectCoursesScreen({
    super.key,
    this.courses,
    this.embedded = false,
    this.onCourseTap,
  });

  // ---- helpers --------------------------------------------------------------

  List<String> _asStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return <String>[];
  }

  /// Stable identity key for a course row (prefer id; else name+semester+campus)
  String _courseKey(Map<String, dynamic> c) {
    final id = (c['id'] ?? '').toString();
    if (id.isNotEmpty) return id;
    final name = (c['name'] ?? '').toString().trim().toLowerCase();
    final sem  = (c['semester'] ?? 'n/a').toString().trim().toLowerCase();
    final camp = (c['campus'] ?? 'n/a').toString().trim().toLowerCase();
    return '$name|$sem|$camp';
  }

  /// Remove duplicates by identity key while preserving last occurrence.
  List<Map<String, dynamic>> _dedupe(List<Map<String, dynamic>> rows) {
    final map = <String, Map<String, dynamic>>{};
    for (final r in rows) {
      map[_courseKey(r)] = r;
    }
    return map.values.toList();
  }

  /// Role-aware list of *rich* course rows to display.
  List<Map<String, dynamic>> _deriveVisibleCoursesRich(MockDatabase db) {
    final userId   = db.currentLoggedInUser ?? '';
    final username = db.getUsernameByEmail(userId) ?? userId; // normalize
    final role     = db.getUserRole(userId);

    final rich = db.getAllCoursesRich()
      ..sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

    if (role == 'admin') return rich;

    if (role == 'teacher') {
      return rich.where((c) => _asStringList(c['lecturers']).contains(username)).toList();
    }

    // STUDENT: union of (enrolled) ∪ (courses where they have projects), without duplicates
    final enrolled = rich.where((c) => _asStringList(c['students']).contains(username)).toList();

    final projectCourseNames = db
        .getAllProjects()
        .where((p) => _asStringList(p['members']).contains(username))
        .map((p) => (p['course'] ?? '').toString())
        .where((s) => s.isNotEmpty && s != 'N/A')
        .toSet();

    final fromProjects = rich
        .where((c) => projectCourseNames.contains((c['name'] ?? '').toString()))
        .toList();

    // dedupe the union; keeps different semester/campus as separate rows
    return _dedupe([...enrolled, ...fromProjects]);
  }

  // ---- UI -------------------------------------------------------------------

  Widget _courseCard(
    BuildContext context, {
    required Map<String, dynamic> rich,
    required VoidCallback onTap,
  }) {
    final theme   = Theme.of(context);
    final isDark  = theme.brightness == Brightness.dark;
    final titleColor = theme.textTheme.titleMedium?.color ??
        theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subColor = theme.textTheme.bodyMedium?.color ??
        (isDark ? Colors.white70 : Colors.black87);
    final chipBg   = isDark ? Colors.white10 : Colors.black12;
    final cardColor= isDark ? AppColors.blueText.withOpacity(0.10) : Colors.blue[50];
    final arrowColor = theme.iconTheme.color ?? AppColors.blueText;

    final name      = (rich['name'] ?? '').toString();
    final semester  = (rich['semester'] ?? 'N/A').toString();
    final campus    = (rich['campus'] ?? 'N/A').toString();

    // ↓ map usernames -> full names (fallback to username if empty)
    final db = MockDatabase();
    final lecturerUsernames = _asStringList(rich['lecturers']);
    final lecturerNames = lecturerUsernames
        .map((u) {
          final full = db.getFullNameByUsername(u) ?? '';
          return full.trim().isNotEmpty ? full : u;
        })
        .toList();

    final students  = _asStringList(rich['students']);

    String lecturerLine;
    if (lecturerNames.isEmpty) {
      lecturerLine = 'Lecturers: —';
    } else if (lecturerNames.length <= 2) {
      lecturerLine = 'Lecturers: ${lecturerNames.join(', ')}';
    } else {
      lecturerLine =
          'Lecturers: ${lecturerNames.take(2).join(', ')} +${lecturerNames.length - 2}';
    }
    final studentLine = 'Students: ${students.length}';

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_month, size: 16),
                              const SizedBox(width: 6),
                              Text(semester, style: GoogleFonts.poppins(color: subColor)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, size: 16),
                              const SizedBox(width: 6),
                              Text(campus, style: GoogleFonts.poppins(color: subColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(lecturerLine, style: GoogleFonts.poppins(fontSize: 13, color: subColor)),
                    const SizedBox(height: 2),
                    Text(studentLine,  style: GoogleFonts.poppins(fontSize: 13, color: subColor)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, color: arrowColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Map<String, dynamic>> rows) {
    final textColor = Theme.of(context).textTheme.titleLarge?.color ??
        Theme.of(context).textTheme.bodyLarge?.color ??
        Colors.black;

    if (rows.isEmpty) {
      return Center(
        child: Text(
          'No courses available. Please try again later.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 18, color: textColor, fontWeight: FontWeight.w500),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text('Courses List',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final richCourse = rows[index];
              final courseName = (richCourse['name'] ?? '').toString();
              return _courseCard(
                context,
                rich: richCourse,
                onTap: () {
                  if (onCourseTap != null) {
                    onCourseTap!(courseName);
                    return;
                  }
                  Navigator.pushNamed(
                    context,
                    '/courseTeams',
                    arguments: {'selectedCourse': courseName},
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = MockDatabase();
    final allRich = db.getAllCoursesRich()
      ..sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

    late final List<Map<String, dynamic>> visibleRich;
    if (courses != null) {
      // When the parent explicitly filters by name(s), we intentionally allow
      // multiple semesters/campuses of the same name to show.
      final names = courses!.toSet();
      visibleRich = allRich.where((c) => names.contains((c['name'] ?? '').toString())).toList();
    } else {
      visibleRich = _deriveVisibleCoursesRich(db);
    }

    if (embedded) return _buildContent(context, visibleRich);

    final textColor = Theme.of(context).textTheme.titleLarge?.color ??
        Theme.of(context).textTheme.bodyLarge?.color ??
        Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Select a Course',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor, fontSize: 20)),
      ),
      body: _buildContent(context, visibleRich),
    );
  }
}
