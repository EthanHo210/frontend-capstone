import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import 'mock_database.dart';
import 'project_status_screen.dart';
import 'app_colors.dart';
import 'main.dart';
import 'package:flutter/scheduler.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> with RouteAware {
  final int _selectedIndex = 0;
  Map<String, String>? _projectInfo;
  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _loadUserRoleAndProject();
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
      db.setProjectInfoForUser(user, matchingProject);
    }

    setState(() {
      _projectInfo = db.getProjectInfoForUser(user);
      _userRole = db.getUserRole(user);
    });
  }

  void _onItemTapped(int index) async {
    final isStudent = _userRole == 'user';
    final effectiveIndex = isStudent ? index + 1 : index;

    if (effectiveIndex == 0 && !isStudent) {
      final result = await Navigator.pushNamed(context, '/start_new_project');
      if (result == true) {
        _loadUserRoleAndProject();
      }
    } else if (effectiveIndex == 1) {
      Navigator.pushNamed(context, '/courseTeams');
    } else if (effectiveIndex == 2) {
      return;
    } else if (effectiveIndex == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsScreen(isAdmin: _userRole == 'admin'),
        ),
      );
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
    final username = db.getUsernameByEmail(db.currentLoggedInUser ?? '') ?? db.currentLoggedInUser ?? '';
    final projects = db.getAllProjects().where((project) {
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
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      ];
    }

    projects.sort((a, b) => DateTime.parse(b['startDate']).compareTo(DateTime.parse(a['startDate'])));

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
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Course: $course', style: GoogleFonts.poppins(fontSize: 12)),
                Text('Deadline: $deadlineFormatted', style: GoogleFonts.poppins(fontSize: 12)),
              ]),
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
    final username = db.getUsernameByEmail(userEmail) ?? userEmail.split('@')[0];
    final isLoggedIn = userEmail != 'Guest';

    final projectInfo = _projectInfo ?? {
      'project': 'No project',
      'contribution': '0%',
      'rank': 'Unranked',
      'course': 'N/A',
      'deadline': '',
    };

    final projectName = projectInfo['project']!;
    final contribution = projectInfo['contribution']!;
    final deadlineRaw = projectInfo['deadline'] ?? 'N/A';
    final deadlineFormatted = deadlineRaw != 'N/A' && deadlineRaw.isNotEmpty
        ? DateFormat('yyyy-MM-dd - HH:mm:ss').format(DateTime.parse(deadlineRaw))
        : 'N/A';

    final completion = int.tryParse(contribution.replaceAll('%', '')) ?? 0;
    final status = db.calculateStatus(deadlineRaw, completion);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'To',
              style: GoogleFonts.kavoon(
                textStyle: const TextStyle(
                  color: Colors.red,
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    Shadow(
                      offset: Offset(4.0, 4.0),
                      blurRadius: 1.5,
                      color: Colors.white,
                    ),
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
                    Shadow(
                      offset: Offset(4.0, 4.0),
                      blurRadius: 1.5,
                      color: Colors.white,
                    ),
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
                    backgroundColor: AppColors.navbar,
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColors.blueText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    username,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: AppColors.blueText,
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
                      color: AppColors.blueText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Current Project: $projectName\n'
                    'Contribution Rate: $contribution\n'
                    'Status: ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: AppColors.blueText,
                    ),
                  ),
                  Text(
                    status,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: getStatusColor(status),
                    ),
                  ),
                  Text(
                    'Deadline: $deadlineFormatted',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.blueText,
                    ),
                  ),
                  if (_userRole != 'user')
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.blueText),
                      tooltip: 'Edit Project Info',
                      onPressed: () async {
                        if (_projectInfo == null || _projectInfo!["project"] == "No project") {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No projects available for edit.'),
                            ),
                          );
                        } else {
                          final result = await Navigator.pushNamed(context, '/edit_project', arguments: _projectInfo);
                          if (result == true) {
                            _loadUserRoleAndProject();
                          }
                        }
                      },
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
                  color: AppColors.blueText,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ..._buildLatestProjects(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: AppColors.blueText,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: AppColors.navbar,
        iconSize: 32,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        items: _userRole == 'user'
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment),
                  label: 'Projects',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.track_changes),
                  label: 'Tracking',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.lightbulb_outline),
                  label: 'Start New',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment),
                  label: 'Projects',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.track_changes),
                  label: 'Tracking',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blueText,
        onPressed: () {
          Navigator.pushNamed(context, '/user_logs');
        },
        tooltip: 'View Members',
        child: const Icon(Icons.group),
      ),
    );
  }
}
