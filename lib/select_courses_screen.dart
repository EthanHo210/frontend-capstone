import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'course_teams_screen.dart'; // only for type reference; fine to keep
import 'app_colors.dart';

class SelectCoursesScreen extends StatelessWidget {
  /// Prefer passing a pre-filtered list from MainDashboard. If null, we’ll compute it.
  final List<String>? courses;

  /// When true, render content-only (no Scaffold/AppBar) so it can live inside DashboardScaffold.
  final bool embedded;

  /// Parent can intercept navigation (used by MainDashboard to open embedded CourseTeams).
  final void Function(String course)? onCourseTap;

  const SelectCoursesScreen({
    super.key,
    this.courses,
    this.embedded = false,
    this.onCourseTap,
  });

  List<String> _deriveVisibleCourses(MockDatabase db) {
    final allProjects = db.getAllProjects();

    final userEmail = db.currentLoggedInUser ?? '';
    final username = db.getUsernameByEmail(userEmail) ?? userEmail; // use username, not email
    final role = db.getUserRole(userEmail);

    if (role == 'admin' || role == 'officer') {
      final raw = db.getCourses();
      if (raw == null) return <String>[];
      return List<String>.from((raw as Iterable).map((e) => e.toString()));
    }

    final set = allProjects
        .where((project) {
          final rawMembers = project['members'];
          final members = rawMembers is List
              ? rawMembers.map((e) => e.toString()).toList()
              : (rawMembers is String
                  ? rawMembers
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList()
                  : <String>[]);
          return members.contains(username);
        })
        .map((p) => (p['course'] ?? '').toString())
        .where((c) => c.isNotEmpty && c != 'N/A')
        .toSet()
        .toList()
      ..sort();

    return set;
  }

  Widget _buildContent(BuildContext context, List<String> visibleCourses) {
    // Theme-aware colors:
    final titleColor = Theme.of(context).textTheme.bodyLarge?.color ??
        Theme.of(context).colorScheme.onSurface;
    final textColor = Theme.of(context).textTheme.titleLarge?.color ??
        Theme.of(context).textTheme.bodyLarge?.color ??
        Colors.black;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // subtle tint for cards
    final cardColor = isDark ? AppColors.blueText.withOpacity(0.10) : Colors.blue[50];
    final arrowColor = Theme.of(context).iconTheme.color ?? AppColors.blueText;

    if (visibleCourses.isEmpty) {
      return Center(
        child: Text(
          'No courses available. Please try again later.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // ⬇⬇ Added header "Courses List" above the list ⬇⬇
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Courses List',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visibleCourses.length,
            itemBuilder: (context, index) {
              final course = visibleCourses[index];
              return Card(
                color: cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(
                    course,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: arrowColor),
                  onTap: () {
                    // Preferred: let MainDashboard handle it (embedded page).
                    if (onCourseTap != null) {
                      onCourseTap!(course);
                      return;
                    }

                    // Fallback: open standalone via named route.
                    Navigator.pushNamed(
                      context,
                      '/courseTeams',
                      arguments: {'selectedCourse': course},
                    );
                  },
                ),
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

    // Use provided list if given; otherwise derive safely (username-based).
    final visibleCourses = courses != null
        ? List<String>.from(courses!)
        : _deriveVisibleCourses(db);

    if (embedded) {
      // Content-only (no Scaffold/AppBar) — perfect for IndexedStack inside DashboardScaffold.
      return _buildContent(context, visibleCourses);
    }

    // Standalone route version (kept for direct navigation like /selectCourse)
    final textColor = Theme.of(context).textTheme.titleLarge?.color ??
        Theme.of(context).textTheme.bodyLarge?.color ??
        Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Select a Course',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 20,
          ),
        ),
      ),
      body: _buildContent(context, visibleCourses),
    );
  }
}
