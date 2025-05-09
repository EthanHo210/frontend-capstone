import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'project_status_screen.dart';
import 'app_colors.dart';

class CourseTeamsScreen extends StatelessWidget {
  const CourseTeamsScreen({super.key});

  Color getStatusColor(String status) {
    switch (status) {
      case 'On-track':
        return Colors.green;
      case 'Delayed':
        return Colors.orange;
      case 'Crisis':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      case 'Overdue':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = MockDatabase();
    final projects = db.getAllProjects();
    final currentUser = db.currentLoggedInUser ?? '';
    final isTeacher = db.isTeacher(currentUser);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.blueText),
        title: Text(
          'Course Teams',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppColors.blueText,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: projects.isEmpty
            ? Center(
                child: Text(
                  'No projects available.\nPlease make one.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: AppColors.blueText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  final name = project['name'] ?? 'Unknown';
                  final members = project['members'] ?? '0';
                  final startDate = project['startDate'] ?? 'N/A';
                  final deadline = project['deadline'] ?? 'N/A';
                  final status = project['status'] ?? 'Unknown';
                  final course = project['course'] ?? 'N/A';

                  return GestureDetector(
                    onTap: () {
                      db.setProjectInfoForUser(currentUser, project);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectStatusScreen(
                            projectName: project['name']!,
                            completionPercentage: 0,
                            status: project['status']!,
                            courseName: project['course'] ?? 'N/A',
                          ),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.purple[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Course: $course',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.blueText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Start Date: $startDate\nDeadline: $deadline',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: $status',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: getStatusColor(status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isTeacher)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: AppColors.blueText),
                                tooltip: 'Edit Project',
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/edit_project',
                                    arguments: project,
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
