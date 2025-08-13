import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'mock_database.dart';
import 'app_colors.dart';
import 'main.dart';
import 'dart:async';
import 'select_courses_screen.dart';
import 'admin_main_hub_screen.dart';
import 'project_status_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> with RouteAware {
  int _selectedIndex = 0;
  Map<String, String>? _projectInfo;
  String _userRole = 'user';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUserRoleAndProject();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadUserRoleAndProject());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    _loadUserRoleAndProject();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadUserRoleAndProject();
  }

  void _loadUserRoleAndProject() {
    final db = MockDatabase();
    final user = db.currentLoggedInUser ?? '';
    final username = db.getUsernameByEmail(user) ?? user;
    final allProjects = db.getAllProjects();

    final matchingProject = allProjects.firstWhere(
      (project) {
        final members = project['members'] is List
            ? List<String>.from(project['members'])
            : (project['members'] as String).split(',').map((e) => e.trim()).toList();
        return members.contains(username);
      },
      orElse: () => {},
    );

    if (matchingProject.isNotEmpty) {
      db.setProjectInfoForUser(user, {
        'name': matchingProject['name'],
        'completion': '0%',
        'status': matchingProject['status'],
        'course': matchingProject['course'],
        'deadline': matchingProject['deadline'],
      });
    }

    setState(() {
      _projectInfo = db.getProjectInfoForUser(user);
      _userRole = db.getUserRole(user);
    });
  }

  Map<String, dynamic>? _getLastCreatedProjectForUser(String username, String role) {
    final allProjects = MockDatabase().getAllProjects();

    // For admins/officers: if there are no projects, return null instead of calling reduce on an empty list.
    if (role == 'admin' || role == 'officer') {
      if (allProjects.isEmpty) return null;
      return allProjects.reduce((a, b) {
        final aTime = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
        final bTime = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
        return aTime.isAfter(bTime) ? a : b;
      });
    }

    final userProjects = allProjects.where((project) {
      final members = project['members'] is List
          ? List<String>.from(project['members'])
          : (project['members'] as String).split(',').map((e) => e.trim()).toList();
      return members.contains(username);
    }).toList();

    if (userProjects.isEmpty) return null;

    return userProjects.reduce((a, b) {
      final aTime = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
      final bTime = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
      return aTime.isAfter(bTime) ? a : b;
    });
  }


  void _onItemTapped(int index) async {
    final db = MockDatabase();
    final user = db.currentLoggedInUser ?? '';
    final username = db.getUsernameByEmail(user) ?? user;

    if (_userRole == 'admin' || _userRole == 'officer') {
      switch (index) {
        case 0:
          final result = await Navigator.pushNamed(context, '/start_new_project');
          if (result == true) _loadUserRoleAndProject();
          break;
        case 1:
          final allProjects = db.getAllProjects();
          final visibleCourses = allProjects
              .map((project) => project['course'].toString())
              .toSet()
              .toList();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SelectCoursesScreen(courses: visibleCourses),
            ),
          );
          break;
        case 2:
          final lastProject = _getLastCreatedProjectForUser(username, _userRole);
          if (lastProject != null) {
            final projectName = lastProject['name'];
            final courseName = lastProject['course'];

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProjectStatusScreen(
                  projectName: projectName,
                  courseName: courseName,
                ),
              ),
            );
          } else {
            // Admins/officers: show a specific message when there are no projects at all
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('There are no projects available.')),
            );
          }
          break;

        case 3:
          Navigator.pushNamed(context, '/settings');
          break;

        case 4:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminMainHubScreen()),
          );
          break;
      }
    } else if (_userRole == 'teacher') {
      switch (index) {
        case 0:
          final result = await Navigator.pushNamed(context, '/start_new_project');
          if (result == true) _loadUserRoleAndProject();
          break;
        case 1:
          final allProjects = db.getAllProjects();
          final visibleCourses = allProjects
              .where((project) {
                final members = project['members'] is List
                    ? List<String>.from(project['members'])
                    : (project['members'] as String).split(',').map((e) => e.trim()).toList();
                return members.contains(username);
              })
              .map((project) => project['course'].toString())
              .toSet()
              .toList();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SelectCoursesScreen(courses: visibleCourses),
            ),
          );
          break;
        case 2:
          final lastProject = _getLastCreatedProjectForUser(username, _userRole);
          if (lastProject != null) {
            final projectName = lastProject['name'];
            final courseName = lastProject['course'];

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProjectStatusScreen(
                  projectName: projectName,
                  courseName: courseName,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("You are not in any project.")),
            );
          }
          break;
        case 3:
          Navigator.pushNamed(context, '/settings');
          break;
      }
    } else {
      // For normal students
      switch (index) {
        case 0:
          final allProjects = db.getAllProjects();
          final visibleCourses = allProjects
              .where((project) {
                final members = project['members'] is List
                    ? List<String>.from(project['members'])
                    : (project['members'] as String).split(',').map((e) => e.trim()).toList();
                return members.contains(username);
              })
              .map((project) => project['course'].toString())
              .toSet()
              .toList();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SelectCoursesScreen(courses: visibleCourses),
            ),
          );
          break;
        case 1:
          final lastProject = _getLastCreatedProjectForUser(username, _userRole);
          if (lastProject != null) {
            final projectName = lastProject['name'];
            final courseName = lastProject['course'];

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProjectStatusScreen(
                  projectName: projectName,
                  courseName: courseName,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("You are not in any project.")),
            );
          }
          break;
        case 2:
          Navigator.pushNamed(context, '/settings');
          break;
      }
    }
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

  List<Widget> _buildLatestProjects() {
    final db = MockDatabase();
    final user = db.currentLoggedInUser ?? '';
    final role = db.getUserRole(user);
    final username = db.getUsernameByEmail(user) ?? user;

    final existingCourses = db.getCourses().toSet();

    final projects = db.getAllProjects().where((project) {
      final projectCourse = project['course']?.toString() ?? '';
      if (!existingCourses.contains(projectCourse)) return false;

      if (role == 'admin' || role == 'officer') return true;

      final members = project['members'] is List
          ? List<String>.from(project['members'])
          : (project['members'] as String).split(',').map((e) => e.trim()).toList();
      return members.contains(username);
    }).toList();

    if (projects.isEmpty) {
      return [
        const SizedBox(height: 12),
        Text(
          'There are currently no projects.',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ];
    }

    projects.sort((a, b) => DateTime.parse(b['startDate']).compareTo(DateTime.parse(a['startDate'])));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return projects.take(3).map((project) {
      final name = project['name'] ?? 'Unnamed';
      final course = project['course'] ?? 'N/A';
      final status = project['status'] ?? 'Unknown';
      final deadline = project['deadline'] ?? '';
      final deadlineFormatted = deadline.isNotEmpty
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(deadline))
          : 'N/A';

      return GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/projectStatus',
            arguments: {
              'projectName': name,
              'completionPercentage': 0,
              'status': status,
              'courseName': course,
            },
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2A3181).withOpacity(0.20)
                : Colors.purple[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    'Course: $course',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  Text(
                    'Deadline: $deadlineFormatted',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
              Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: getStatusColor(status),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final db = MockDatabase();
    final userEmail = db.currentLoggedInUser ?? 'Guest';
    final username = db.getUsernameByEmail(userEmail) ?? userEmail;

    String fullName = db.getFullNameByUsername(username) ?? '';
    if (fullName.isEmpty) {
      final userRecord = db.getUserByEmail(userEmail);
      if (userRecord != null && (userRecord['fullName'] ?? '').toString().isNotEmpty) {
        fullName = userRecord['fullName'];
      }
    }
    final displayName =
        fullName.isNotEmpty ? fullName : (username.contains('@') ? username.split('@')[0] : username);

    final isLoggedIn = userEmail != 'Guest';

    final projectInfo = _projectInfo ?? {
      'project': 'No project',
      'rank': 'Unranked',
      'course': 'N/A',
      'deadline': '',
    };

    final projectName = projectInfo['name'] ?? projectInfo['project'] ?? 'No project';
    final deadlineRaw = projectInfo['deadline'] ?? 'N/A';
    final deadlineFormatted = deadlineRaw != 'N/A' && deadlineRaw.isNotEmpty
        ? DateFormat('yyyy-MM-dd - HH:mm:ss').format(DateTime.parse(deadlineRaw))
        : 'N/A';

    // THEME-ADAPTIVE TEXT COLORS
    final textTheme = Theme.of(context).textTheme;
    final titleColor = textTheme.titleLarge?.color ?? Theme.of(context).colorScheme.onBackground;
    final bodyColor  = textTheme.bodyMedium?.color ?? Theme.of(context).colorScheme.onBackground;
    final navColor = Theme.of(context).textTheme.bodyMedium?.color ?? Theme.of(context).colorScheme.onBackground;
    final projectStatus = (_projectInfo != null) ? (_projectInfo!['status'] ?? 'N/A') : 'N/A';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo stays brand colors regardless of theme
            Text(
              'To',
              style: GoogleFonts.kavoon(
                textStyle: const TextStyle(
                  color: Colors.red,
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    Shadow(offset: Offset(4.0, 4.0), blurRadius: 1.5, color: Colors.white),
                  ],
                ),
              ),
            ),
            Text(
              'gether!',
              style: GoogleFonts.kavoon(
                textStyle: const TextStyle(
                  color: Color.fromRGBO(42, 49, 129, 1),
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    Shadow(offset: Offset(4.0, 4.0), blurRadius: 1.5, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: titleColor, // ADAPTIVE
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: titleColor, // ADAPTIVE
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Text(
                    'LAST UPDATED',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: titleColor, // ADAPTIVE
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Current Project: $projectName\nStatus: ',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: bodyColor,
                          ),
                        ),
                        TextSpan(
                          text: projectStatus,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            // use your helper to color status (falls back to bodyColor if unknown)
                            color: getStatusColor(projectStatus) ?? bodyColor,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Deadline: $deadlineFormatted',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: bodyColor, // ADAPTIVE
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Your project',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: titleColor, // ADAPTIVE
                ),
              ),
            ),
            const SizedBox(height: 24),
            ..._buildLatestProjects(),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // make selected/unselected identical so nothing looks highlighted
        selectedItemColor: navColor,
        unselectedItemColor: navColor,
        // ensure icons also use the same color
        selectedIconTheme: IconThemeData(color: navColor),
        unselectedIconTheme: IconThemeData(color: navColor),
        // keep labels the same too
        selectedLabelStyle: TextStyle(color: navColor),
        unselectedLabelStyle: TextStyle(color: navColor),
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Theme.of(context).colorScheme.surface,
        iconSize: 32,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        items: _userRole == 'user'
            ? const [
                BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects'),
                BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Tracking'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
              ]
            : (_userRole == 'admin' || _userRole == 'officer')
                ? const [
                    BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline), label: 'Start New'),
                    BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects'),
                    BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Tracking'),
                    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
                    BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Manage'),
                  ]
                : const [
                    BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline), label: 'Start New'),
                    BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects'),
                    BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Tracking'),
                    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
                  ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blueText, // brand-locked
        onPressed: () => Navigator.pushNamed(context, '/user_logs'),
        tooltip: 'View Members',
        child: const Icon(Icons.group, color: Colors.white),
      ),
    );
  }
}
