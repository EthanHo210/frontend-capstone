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
    final visibleCourses = allProjects
        .where((project) {
          final members = project['members'] is List
              ? List<String>.from(project['members'])
              : (project['members'] as String).split(',').map((e) => e.trim()).toList();
          return members.contains(currentUser);
        })
        .map((project) => project['course'] as String)
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.blueText),
        title: Text(
          'Select a Course',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.blueText,
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
                  color: AppColors.blueText,
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
                  color: Colors.blue[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(
                      course,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
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
