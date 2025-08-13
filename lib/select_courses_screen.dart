import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'course_teams_screen.dart';
import 'app_colors.dart';

class SelectCoursesScreen extends StatelessWidget {
  final List<String> courses;

  const SelectCoursesScreen({Key? key, required this.courses}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final db = MockDatabase();
    final currentUser = db.currentLoggedInUser;
    final allProjects = db.getAllProjects();

    // Collect courses only if user is a member of associated project
    final userRole = db.getUserRole(currentUser ?? '');
    final visibleCourses = (userRole == 'admin' || userRole == 'officer')
        ? db.getCourses() // Admin sees all
        : allProjects
            .where((project) {
              final members = project['members'] is List
                  ? List<String>.from(project['members'])
                  : (project['members'] as String).split(',').map((e) => e.trim()).toList();
              return members.contains(currentUser);
            })
            .map((project) => project['course'] as String)
            .toSet()
            .toList();

    // Theme-aware colors:
    final textColor = Theme.of(context).textTheme.titleLarge?.color
        ?? Theme.of(context).textTheme.bodyLarge?.color
        ?? Colors.black;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // keep a subtle blue tint in light mode, and a faint indigo tint in dark mode for cards
    final cardColor = isDark ? AppColors.blueText.withOpacity(0.10) : Colors.blue[50];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // let AppBar's iconTheme pick up the text color
        iconTheme: IconThemeData(color: textColor),
        leading: BackButton(), // color comes from iconTheme
        title: Text(
          'Select a Course',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 20,
          ),
        ),
      ),
      body: visibleCourses.isEmpty
          ? Center(
              child: Text(
                'No courses available. Please try again later.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : ListView.builder(
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
                    // trailing arrow kept brand-locked; change to `textColor` if you want it to adapt instead
                    trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.blueText),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseTeamsScreen(selectedCourse: course),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
