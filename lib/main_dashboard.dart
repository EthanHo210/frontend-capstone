// main_dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'mock_database.dart';
import 'app_colors.dart';
import 'select_courses_screen.dart';
import 'admin_main_hub_screen.dart';
import 'project_status_screen.dart';
import 'settings_screen.dart';
import 'route_observer.dart';
import 'start_new_project.dart';
import 'user_logs_screen.dart';
import 'about_app_screen.dart';
import 'admin_dashboard.dart';
import 'assign_leader_screen.dart';
import 'help_center_screen.dart';
import 'manage_courses_screen.dart';
import 'dashboard_scaffold.dart';
import 'course_teams_screen.dart';
import 'assign_task_screen.dart';
import 'update_password_screen.dart';
import 'manage_users_screen.dart';


class MainDashboard extends StatefulWidget {
  final bool isDarkMode;
  final void Function(bool)? onToggleTheme;

  const MainDashboard({
    super.key,
    this.isDarkMode = false,
    this.onToggleTheme,
  });

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> with RouteAware {
  int _selectedIndex = 0;
  int? _previousIndex;
  Map<String, String>? _projectInfo;
  String _userRole = 'user';
  Timer? _refreshTimer;

  Map<String, String>? _selectedProjectForStatus;

  // NEW: which course user tapped in SelectCoursesScreen
  String? _selectedCourseForTeams;
  String? _assignTaskProjectName;
  String? _assignLeaderProjectName;

  final Map<String, int> _extraIndex = {};

  @override
  void initState() {
    super.initState();
    _loadUserRoleAndProject();
    _startAutoRefresh();
  }

  void _openUpdatePasswordEmbedded() => _openExtra('updatePassword');


  void _showStartNewSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return const FractionallySizedBox(
          heightFactor: 0.95,
          child: StartNewProjectScreen(),
        );
      },
    );
    if (created == true) _loadUserRoleAndProject();
  }

  void _startAutoRefresh() {
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _loadUserRoleAndProject());
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
            : (project['members'] as String)
                .split(',')
                .map((e) => e.trim())
                .toList();
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

      final bottomCount = _currentBottomItemCount();
      if (_selectedIndex >= bottomCount && _previousIndex == null) {
        _selectedIndex = 0;
      }
    });
  }

  Map<String, dynamic>? _getLastCreatedProjectForUser(String username, String role) {
    final allProjects = MockDatabase().getAllProjects();

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
          : (project['members'] as String)
              .split(',')
              .map((e) => e.trim())
              .toList();
      return members.contains(username);
    }).toList();

    if (userProjects.isEmpty) return null;

    return userProjects.reduce((a, b) {
      final aTime = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
      final bTime = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
      return aTime.isAfter(bTime) ? a : b;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedProjectForStatus = null;
      _previousIndex = null;
    });

    if ((_userRole == 'admin' || _userRole == 'officer' || _userRole == 'teacher') &&
        index == 0) {
      Future.microtask(() => _showStartNewSheet());
    }
  }

  bool _isStartNewTabSelected() {
    return (_userRole == 'admin' || _userRole == 'officer' || _userRole == 'teacher') &&
        _selectedIndex == 0;
  }

  int _indexOfTrackingTab() {
    if (_userRole == 'admin' || _userRole == 'officer') return 2;
    if (_userRole == 'teacher') return 2;
    return 1;
  }

  int _currentBottomItemCount() {
    if (_userRole == 'user') return 3;
    if (_userRole == 'admin' || _userRole == 'officer') return 5;
    return 4; // teacher
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

  Widget _wrapWithHeader(Widget child, {required String title, VoidCallback? onClose}) {
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

    final titleColor =
        Theme.of(context).textTheme.titleLarge?.color ?? Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onClose ??
                      () {
                        setState(() {
                          _selectedIndex = _previousIndex ?? 0;
                          _previousIndex = null;
                        });
                      },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  void _openExtra(String key) {
    final idx = _extraIndex[key];
    if (idx == null) return;
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = idx;
    });
  }

  void _openAboutEmbedded() => _openExtra('about');
  void _openHelpEmbedded() => _openExtra('help');
  void _openMembersEmbedded() => _openExtra('members');
  void _openAdminDashboardEmbedded() => _openExtra('admin');
  void _openManageCoursesEmbedded() => _openExtra('courses');
  void _openAssignLeaderEmbedded() => _openExtra('assignLeader');
  void _openCourseTeamsEmbedded() => _openExtra('courseTeams');
  void _openAssignTaskEmbedded() => _openExtra('assignTask');


  // call this when a course is picked
  void _openCourseTeamsFor(String course) {
    setState(() {
      _selectedCourseForTeams = course;
    });
    _openCourseTeamsEmbedded();
  }

  List<Widget> _pagesForRole() {
    final db = MockDatabase();
    final user = db.currentLoggedInUser ?? '';
    final username = db.getUsernameByEmail(user) ?? user;


    Widget trackingPage() {
      final lastProject = _getLastCreatedProjectForUser(username, _userRole);
      final projectToShow = _selectedProjectForStatus != null
          ? {
              'name': _selectedProjectForStatus!['projectName'],
              'course': _selectedProjectForStatus!['courseName'],
              'status': lastProject?['status'] ?? 'Unknown',
            }
          : lastProject;

      if (projectToShow != null) {
        return ProjectStatusScreen(
          projectName: projectToShow['name'],
          courseName: projectToShow['course'],
          embedded: true, // avoid nested Scaffold/AppBar
          onOpenAssignTaskEmbedded: () {
            setState(() {
              _assignTaskProjectName = projectToShow['name'];
            });
            _openAssignTaskEmbedded();
          },
          // NEW: open Assign Leader extra for the currently viewed project
          onOpenAssignLeaderEmbedded: () {
            setState(() {
              _assignLeaderProjectName = projectToShow['name'];
            });
            _openAssignLeaderEmbedded();
          },
        );
      } else {
        return Center(
          child: Text(
            _userRole == 'admin' || _userRole == 'officer'
                ? 'There are no projects available.'
                : 'You are not in any project.',
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        );
      }
    }

    List<Widget> basePages;

    if (_userRole == 'admin' || _userRole == 'officer') {
      final allProjects = db.getAllProjects();
      final visibleCourses =
          allProjects.map((p) => p['course'].toString()).toSet().toList();
      final trackingPageWidget = trackingPage();

      basePages = [
        Center(
          child: ElevatedButton.icon(
            onPressed: _showStartNewSheet,
            icon: const Icon(Icons.add),
            label: const Text('Start New Project'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        // IMPORTANT: embedded + onCourseTap
        SelectCoursesScreen(
          courses: visibleCourses,
          embedded: true,
          onCourseTap: _openCourseTeamsFor,
        ),
        trackingPageWidget,
        
        SettingsScreen(
          isAdmin: true,
          isDarkMode: Theme.of(context).brightness == Brightness.dark, // <-- use live theme
          onToggleTheme: widget.onToggleTheme,
          onOpenAbout: _openAboutEmbedded,
          onOpenMembers: _openMembersEmbedded,
          onOpenHelpCenter: _openHelpEmbedded,
          onOpenUpdatePassword: _openUpdatePasswordEmbedded,
        ),
        AdminMainHubScreen(
          onNavigate: (action) {
            if (action == 'manage_users') {
              _openAdminDashboardEmbedded();
            } else if (action == 'manage_courses') {
              _openManageCoursesEmbedded();
            }
          },
        ),
      ];
    } else if (_userRole == 'teacher') {
        final allProjects = db.getAllProjects();
        final visibleCourses = allProjects
            .where((p) {
              final members = p['members'] is List
                  ? List<String>.from(p['members'])
                  : (p['members'] as String).split(',').map((e) => e.trim()).toList();
              return members.contains(username);
            })
            .map((p) => p['course'].toString())
            .toSet()
            .toList();

        final trackingPageWidget = trackingPage();

        basePages = [
          // ⬇️ change this page from plain text to a real button
          Center(
            child: ElevatedButton.icon(
              onPressed: _showStartNewSheet,
              icon: const Icon(Icons.add),
              label: const Text('Start New Project'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          SelectCoursesScreen(
            courses: visibleCourses,
            embedded: true,
            onCourseTap: _openCourseTeamsFor,
          ),
          trackingPageWidget,
         SettingsScreen(
          isAdmin: false,
          isDarkMode: Theme.of(context).brightness == Brightness.dark, // <-- use live theme
          onToggleTheme: widget.onToggleTheme,
          onOpenAbout: _openAboutEmbedded,
          onOpenMembers: _openMembersEmbedded,
          onOpenHelpCenter: _openHelpEmbedded,
        ),
        ];
      } else {
      // Students / normal users
      final allProjects = db.getAllProjects();
      final visibleCourses = allProjects
          .where((p) {
            final members = p['members'] is List
                ? List<String>.from(p['members'])
                : (p['members'] as String)
                    .split(',')
                    .map((e) => e.trim())
                    .toList();
            return members.contains(username);
          })
          .map((p) => p['course'].toString())
          .toSet()
          .toList();

      final trackingPageWidget = trackingPage();

      basePages = [
        SelectCoursesScreen(
          courses: visibleCourses,
          embedded: true,
          onCourseTap: _openCourseTeamsFor,
        ),

        trackingPageWidget,
        SettingsScreen(
          isAdmin: false,
          isDarkMode: Theme.of(context).brightness == Brightness.dark, // <-- use live theme
          onToggleTheme: widget.onToggleTheme,
          onOpenAbout: _openAboutEmbedded,
          onOpenMembers: _openMembersEmbedded,
          onOpenHelpCenter: _openHelpEmbedded,
        ),
      ];
    }

    // ----- Build extra pages and register indices -----
    _extraIndex.clear();
    final extras = <Widget>[];

    Widget _addExtra(String key, Widget child, String title) {
      

      final wrapped = _wrapWithHeader(
        child,
        title: title,
        onClose: () {
          setState(() {
            _selectedIndex = _previousIndex ?? 0;
            _previousIndex = null;
          });
        },
      );
      _extraIndex[key] = _currentBottomItemCount() + extras.length;
      extras.add(wrapped);
      return wrapped;
    }
        
    _addExtra('about', const AboutAppScreen(embedded: true), 'About App');
    _addExtra('help', const HelpCenterScreen(embedded: true), 'Help Center');
    _addExtra('members', UserLogsScreen(), 'User Directory');
    _addExtra(
      'admin',
      const ManageUsersScreen(embedded: true),
      'Manage Users',
    );

    _addExtra(
      'courses',
      ManageCoursesScreen(
        embedded: true,
        onCoursesChanged: () {
          setState(_loadUserRoleAndProject);
        },
      ),
      'Manage Courses',
    );

    // FIX: build CourseTeams extra with selectedCourse (or placeholder)
    _addExtra(
      'courseTeams',
      (_selectedCourseForTeams == null)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Pick a course to view its teams.',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
            )
          : CourseTeamsScreen(
              selectedCourse: _selectedCourseForTeams!,
              embedded: true,
              onBack: () {
                setState(() {
                  _selectedCourseForTeams = null;
                  _selectedIndex = 1; // or whatever tab shows SelectCoursesScreen
                });
              },
              onOpenProject: (projectName, courseName) {
                setState(() {
                  _selectedProjectForStatus = {
                    'projectName': projectName,
                    'courseName': courseName,
                  };
                  _selectedIndex = _indexOfTrackingTab(); // shows embedded ProjectStatusScreen
                });
              },
            ),
      'Projects List',
    );

    _addExtra(
      'assignLeader',
      (_assignLeaderProjectName == null)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Open a project first to assign a leader.',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
            )
          : AssignLeaderScreen(
              projectName: _assignLeaderProjectName!, // use the chosen project
              embedded: true,
              onAssigned: (assignedUsername) {
                if (mounted) {
                  setState(_loadUserRoleAndProject);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$assignedUsername assigned as leader'),
                    backgroundColor: AppColors.blueText,
                  ),
                );
              },
            ),
      'Assign Leader',
    );


    _addExtra(
      'assignTask',
      (_assignTaskProjectName == null)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Open a project first to assign a task.',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
            )
          : AssignTaskScreen(
              projectName: _assignTaskProjectName!,
              embedded: true,
              onCreated: (created) {
                if (created) {
                  setState(_loadUserRoleAndProject);
                }
              },
            ),
      'Assign Task',
    );

    _addExtra(
      'updatePassword',
      const UpdatePasswordScreen(embedded: true),
      'Update Password',
    );

    return [...basePages, ...extras];
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
    final displayName = fullName.isNotEmpty
        ? fullName
        : (username.contains('@') ? username.split('@')[0] : username);
    final isLoggedIn = userEmail != 'Guest';

    final projectInfo = _projectInfo ??
        {'project': 'No project', 'rank': 'Unranked', 'course': 'N/A', 'deadline': ''};
    final projectName = projectInfo['name'] ?? projectInfo['project'] ?? 'No project';
    final deadlineRaw = projectInfo['deadline'] ?? 'N/A';
    final deadlineFormatted = deadlineRaw != 'N/A' && deadlineRaw.isNotEmpty
        ? DateFormat('yyyy-MM-dd - HH:mm:ss').format(DateTime.parse(deadlineRaw))
        : 'N/A';

    final textTheme = Theme.of(context).textTheme;
    final titleColor =
        textTheme.titleLarge?.color ?? Theme.of(context).colorScheme.onSurface;
    final bodyColor =
        textTheme.bodyMedium?.color ?? Theme.of(context).colorScheme.onSurface;
    final projectStatus =
        (_projectInfo != null) ? (_projectInfo!['status'] ?? 'N/A') : 'N/A';

    final pages = _pagesForRole();

    final bottomItems = _userRole == 'user'
        ? const [
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects'),
            BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Tracking'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ]
        : (_userRole == 'admin' || _userRole == 'officer')
            ? const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.lightbulb_outline), label: 'Start New'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.assignment), label: 'Projects'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.track_changes), label: 'Tracking'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.manage_accounts), label: 'Manage'),
              ]
            : const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.lightbulb_outline), label: 'Start New'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.assignment), label: 'Projects'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.track_changes), label: 'Tracking'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
              ];

    return DashboardScaffold(
      appBarTitle: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          'To',
          style: GoogleFonts.kavoon(
            textStyle: const TextStyle(
              color: Colors.red,
              fontSize: 35,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              shadows: [
                Shadow(offset: Offset(4.0, 4.0), blurRadius: 1.5, color: Colors.white)
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
                Shadow(offset: Offset(4.0, 4.0), blurRadius: 1.5, color: Colors.white)
              ],
            ),
          ),
        ),
      ]),
      displayName: isLoggedIn ? displayName : null,
      body: Column(children: [
        if (_isStartNewTabSelected()) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const SizedBox(height: 12),
              Text('LAST UPDATED',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 16, color: titleColor)),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: 'Current Project: $projectName\nStatus: ',
                    style: GoogleFonts.poppins(fontSize: 16, color: bodyColor),
                  ),
                  TextSpan(
                    text: projectStatus,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: getStatusColor(projectStatus)),
                  ),
                ]),
                textAlign: TextAlign.center,
              ),
              Text('Deadline: $deadlineFormatted',
                  style: GoogleFonts.poppins(fontSize: 16, color: bodyColor)),
            ]),
          ),
          const SizedBox(height: 8),
        ],
        Expanded(child: IndexedStack(index: _selectedIndex, children: pages)),
      ]),
      bottomItems: bottomItems,
      currentIndex: (_selectedIndex < bottomItems.length) ? _selectedIndex : 0,
      onTap: (i) {
        if (i < pages.length) _onItemTapped(i);
      },
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blueText,
        onPressed: _openMembersEmbedded,
        tooltip: 'View Members',
        child: const Icon(Icons.group, color: Colors.white),
      ),
    );
  }
}
