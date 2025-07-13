import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'mock_database.dart';
import 'project_status_screen.dart';
import 'edit_project_screen.dart';
import 'app_colors.dart';
import 'main.dart';

class CourseTeamsScreen extends StatefulWidget {
  final String selectedCourse;
  const CourseTeamsScreen({super.key, required this.selectedCourse});

  @override
  State<CourseTeamsScreen> createState() => _CourseTeamsScreenState();
}

class _CourseTeamsScreenState extends State<CourseTeamsScreen> with RouteAware {
  final db = MockDatabase();
  late List<Map<String, dynamic>> projects;
  late String currentUser;
  late String username;
  late bool isTeacher;

  @override
  void initState() {
    super.initState();
    currentUser = db.currentLoggedInUser ?? '';
    username = db.getUsernameByEmail(currentUser) ?? currentUser;
    isTeacher = db.isTeacher(currentUser);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    _loadProjects();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {
      _loadProjects();
    });
  }

  void _loadProjects() {
    final allProjects = db.getAllProjects();
    final role = db.getUserRole(currentUser);
    
    projects = allProjects.where((project) {
      final course = project['course'] ?? 'N/A';
      if (course != widget.selectedCourse) return false;

      final rawMembers = project['members'];
      List<String> members;
      if (rawMembers is String) {
        members = rawMembers
            .split(',')
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toList();
      } else if (rawMembers is List) {
        members = rawMembers.cast<String>();
      } else {
        members = [];
      }

      return members.contains(username) || role == 'admin' || role == 'officer';
    }).toList();
  }


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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.blueText),
        title: Text(
          'Project List',
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
                  final course = project['course'] ?? 'N/A';
                  final status = project['status'] ?? 'Unknown';

                  final rawStartDate = project['startDate'];
                  final rawDeadline = project['deadline'];

                  final startDateFormatted = rawStartDate != null
                      ? DateFormat('yyyy-MM-dd - HH:mm:ss').format(DateTime.parse(rawStartDate))
                      : 'N/A';

                  final deadlineFormatted = rawDeadline != null
                      ? DateFormat('yyyy-MM-dd - HH:mm:ss').format(DateTime.parse(rawDeadline))
                      : 'N/A';

                  final rawMembers = project['members'];
                  final memberIds = rawMembers is String
                      ? rawMembers
                          .split(',')
                          .map((id) => id.trim())
                          .where((id) => id.isNotEmpty)
                          .toList()
                      : (rawMembers as List<dynamic>).cast<String>();

                  final studentNames = memberIds
                      .map((id) {
                        final user = db.getUserNameById(id);
                        return user != null ? user[0].toUpperCase() + user.substring(1) : 'Unknown';
                      })
                      .toList();

                  return GestureDetector(
                    onTap: () {
                      db.setProjectInfoForUser(currentUser, project);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectStatusScreen(
                            projectName: project['name']!,
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
                                  'Start Date: $startDateFormatted\nDeadline: $deadlineFormatted',
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
                                const SizedBox(height: 6),
                                if (studentNames.isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Students:',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      ...studentNames.map((name) => Text(
                                            '- $name',
                                            style: GoogleFonts.poppins(fontSize: 12),
                                          )),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          if (isTeacher || db.getUserRole(currentUser) == 'admin' || db.getUserRole(currentUser) == 'officer')
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: AppColors.blueText),
                                tooltip: 'Edit Project',
                                onPressed: () async {
                                  final updatedProject = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditProjectScreen(project: Map<String, dynamic>.from(project)),
                                    ),
                                  );
                                  if (updatedProject != null) {
                                    setState(() {
                                      _loadProjects();
                                    });
                                  }
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
