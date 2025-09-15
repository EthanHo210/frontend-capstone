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

  // Which course user tapped in SelectCoursesScreen
  String? _selectedCourseForTeams;
  String? _assignTaskProjectName;
  String? _assignLeaderProjectName;
  int _projectStatusRefresh = 0;

  // NEW: track whether ProjectStatus was opened from the admin Tracking list
  bool _statusFromTrackingList = false;

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
      _statusFromTrackingList = false;
      _previousIndex = null;
    });
  }

  int _indexOfTrackingTab() => 1; // Projects=0, Tracking=1 for every role now
  int _projectsTabIndex() => 0;   // Projects is always the first tab

  int _currentBottomItemCount() {
    if (_userRole == 'user') return 3;
    if (_userRole == 'admin' || _userRole == 'officer') return 4;
    return 3; // teacher
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

  String _formatDate(dynamic raw) {
    if (raw == null) return 'N/A';
    try {
      final dt = DateTime.parse(raw.toString());
      return DateFormat('yyyy-MM-dd – HH:mm:ss').format(dt);
    } catch (_) {
      return raw.toString();
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
      // -------------------------
      // Admin/Officer: show ALL ACTIVE projects list.
      // -------------------------
      if (_userRole == 'admin' || _userRole == 'officer') {
        // If a project is currently opened (from the list or course teams),
        // render its status with a context-aware Back.
        if (_selectedProjectForStatus != null) {
          final pName = _selectedProjectForStatus!['projectName']!;
          final cName = _selectedProjectForStatus!['courseName']!;
          final screen = ProjectStatusScreen(
            projectName: pName,
            courseName: cName,
            embedded: true,
            refreshTick: _projectStatusRefresh,
            onOpenAssignTaskEmbedded: () {
              setState(() {
                _assignTaskProjectName = pName;
              });
              _openAssignTaskEmbedded();
            },
            onOpenAssignLeaderEmbedded: () {
              setState(() {
                _assignLeaderProjectName = pName;
              });
              _openAssignLeaderEmbedded();
            },
          );

          // Back: if the project came from Tracking list, go back to the list.
          // Otherwise (navigated from Course→Teams), go back to Projects.
          final goBackToProjects =
              !(_userRole == 'admin' || _userRole == 'officer') || !_statusFromTrackingList;

          return _wrapWithHeader(
            screen,
            title: 'Project Status',
            onClose: () {
              setState(() {
                if (_statusFromTrackingList) {
                  // back to tracking list
                  _selectedProjectForStatus = null;
                  _statusFromTrackingList = false;
                } else {
                  // back to Projects → course teams
                  _selectedIndex = _projectsTabIndex();
                  _statusFromTrackingList = false;
                }
              });
              if (!(_statusFromTrackingList)) {
                _openCourseTeamsEmbedded();
              }
            },
          );
        }

        // Build the list of active (not overdue) projects
        final all = db.getAllProjects();
        final now = DateTime.now();

        bool isActive(Map<String, dynamic> p) {
          final raw = (p['deadline'] ?? '').toString();
          final d = DateTime.tryParse(raw);
          if (d == null) return true; // unknown dates → show
          return d.isAfter(now);
        }

        final active = all.where(isActive).toList()
          ..sort((a, b) {
            final ad = DateTime.tryParse((a['deadline'] ?? '').toString()) ?? DateTime(2100);
            final bd = DateTime.tryParse((b['deadline'] ?? '').toString()) ?? DateTime(2100);
            return ad.compareTo(bd);
          });


        if (active.isEmpty) {
          return Center(
            child: Text(
              'No active projects.',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ListView.builder(
            itemCount: active.length,
            itemBuilder: (context, i) {
              final p = active[i];
              final name = (p['name'] ?? 'Unknown').toString();
              final course = (p['course'] ?? 'N/A').toString();
              final status = (p['status'] ?? 'Unknown').toString();
              final deadline = _formatDate(p['deadline']);
              final members = (p['members'] is List)
                  ? List<String>.from(p['members'])
                  : (p['members']?.toString() ?? '')
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Course: $course',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodyMedium?.color)),
                        const SizedBox(height: 4),
                        Text('Deadline: $deadline',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodyMedium?.color)),
                        const SizedBox(height: 4),
                        Text('Status: $status',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: getStatusColor(status))),
                        const SizedBox(height: 4),
                        Text('Members: ${members.length}',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodyMedium?.color)),
                      ],
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedProjectForStatus = {
                          'projectName': name,
                          'courseName': course,
                        };
                        _statusFromTrackingList = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.button,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Open', style: GoogleFonts.poppins()),
                  ),
                ),
              );
            },
          ),
        );
      }

      // -------------------------
      // Teacher/User: keep existing logic (last project or selected)
      // -------------------------
      final lastProject = _getLastCreatedProjectForUser(username, _userRole);
      final projectToShow = _selectedProjectForStatus != null
          ? {
              'name': _selectedProjectForStatus!['projectName'],
              'course': _selectedProjectForStatus!['courseName'],
              'status': lastProject?['status'] ?? 'Unknown',
            }
          : lastProject;

      if (projectToShow != null) {
        final screen = ProjectStatusScreen(
          projectName: projectToShow['name'],
          courseName: projectToShow['course'],
          embedded: true,
          refreshTick: _projectStatusRefresh,
          onOpenAssignTaskEmbedded: () {
            setState(() {
              _assignTaskProjectName = projectToShow['name'];
            });
            _openAssignTaskEmbedded();
          },
          onOpenAssignLeaderEmbedded: () {
            setState(() {
              _assignLeaderProjectName = projectToShow['name'];
            });
            _openAssignLeaderEmbedded();
          },
        );

        return _wrapWithHeader(
          screen,
          title: 'Project Status',
          onClose: () {
            // Back goes to Projects list
            setState(() {
              _selectedIndex = _projectsTabIndex();
            });
            _openCourseTeamsEmbedded();
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
      final trackingPageWidget = trackingPage();

      basePages = [
        SelectCoursesScreen(
          courses: null,
          embedded: true,
          onCourseTap: _openCourseTeamsFor,
        ),
        trackingPageWidget,
        SettingsScreen(
          isAdmin: true,
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
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
      final trackingPageWidget = trackingPage();

      basePages = [
        SelectCoursesScreen(
          courses: null,
          embedded: true,
          onCourseTap: _openCourseTeamsFor,
        ),
        trackingPageWidget,
        SettingsScreen(
          isAdmin: false,
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
          onToggleTheme: widget.onToggleTheme,
          onOpenAbout: _openAboutEmbedded,
          onOpenMembers: _openMembersEmbedded,
          onOpenHelpCenter: _openHelpEmbedded,
        ),
      ];
    } else {
      // Students / normal users
      final trackingPageWidget = trackingPage();

      basePages = [
        SelectCoursesScreen(
          courses: null,
          embedded: true,
          onCourseTap: _openCourseTeamsFor,
        ),
        trackingPageWidget,
        SettingsScreen(
          isAdmin: false,
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
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

    Widget addExtra(String key, Widget child, String title) {
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

    addExtra('about', const AboutAppScreen(embedded: true), 'About App');
    addExtra('help', const HelpCenterScreen(embedded: true), 'Help Center');
    addExtra('members', UserLogsScreen(), 'User Directory');
    addExtra('admin', const ManageUsersScreen(embedded: true), 'Manage Users');

    addExtra(
      'courses',
      ManageCoursesScreen(
        embedded: true,
        onCoursesChanged: () {
          setState(_loadUserRoleAndProject);
        },
      ),
      'Manage Courses',
    );

    addExtra(
      'courseTeams',
      (_selectedCourseForTeams == null)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Pick a course to view its teams.',
                    style: GoogleFonts.poppins(fontSize: 16)),
              ),
            )
          : CourseTeamsScreen(
              selectedCourse: _selectedCourseForTeams!,
              embedded: true,
              onOpenProject: (projectName, courseName) {
                setState(() {
                  _selectedProjectForStatus = {
                    'projectName': projectName,
                    'courseName': courseName,
                  };
                  _statusFromTrackingList = false; // came from course teams
                  _selectedIndex = _indexOfTrackingTab(); // jump to Project Status tab
                });
              },
              // ✅ keep dashboard chrome when starting a project from here
              onStartNewProject: _showStartNewSheet,
            ),
      'Projects List',
    );

    addExtra(
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
              projectName: _assignLeaderProjectName!,
              embedded: true,
              onAssigned: (assignedUsername) {
                final full = MockDatabase().getFullNameByUsername(assignedUsername) ??
                    assignedUsername;
                if (mounted) {
                  setState(() {
                    _loadUserRoleAndProject();
                    _assignLeaderProjectName = null;
                    _selectedIndex = _indexOfTrackingTab();
                    _projectStatusRefresh++;
                  });
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$full assigned as leader'),
                    backgroundColor: AppColors.blueText,
                  ),
                );
              },
            ),
      'Assign Leader',
    );

    addExtra(
      'assignTask',
      (_assignTaskProjectName == null)
          ? Center(/* ... */)
          : AssignTaskScreen(
              projectName: _assignTaskProjectName!,
              embedded: true,
              onCreated: (created) {
                if (created) {
                  setState(() {
                    _loadUserRoleAndProject();
                    _assignTaskProjectName = null;
                    _selectedIndex = _indexOfTrackingTab();
                    _projectStatusRefresh++;
                  });
                }
              },
            ),
      'Assign Task',
    );

    addExtra(
      'updatePassword',
      const UpdatePasswordScreen(embedded: true),
      'Update Password',
    );

    return [...basePages, ...extras];
  }

  Widget? _buildFab() {
  // Show FAB only on the Projects tab
    if (_selectedIndex != _projectsTabIndex()) return null;

    // Admin/Officer/Teacher: add project
    if (_userRole == 'admin' || _userRole == 'officer' || _userRole == 'teacher') {
      return FloatingActionButton.extended(
        onPressed: _showStartNewSheet,
        backgroundColor: AppColors.blueText,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Project',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        tooltip: 'Add Project',
      );
    }

    // Students: keep your existing FAB (or switch to extended if you want a label too)
    return FloatingActionButton(
      backgroundColor: AppColors.blueText,
      onPressed: _openMembersEmbedded,
      tooltip: 'View Members',
      child: const Icon(Icons.group, color: Colors.white),
    );
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

    final projectInfo = _projectInfo ??
        {'project': 'No project', 'rank': 'Unranked', 'course': 'N/A', 'deadline': ''};
    final deadlineRaw = projectInfo['deadline'] ?? 'N/A';
    final deadlineFormatted = deadlineRaw != 'N/A' && deadlineRaw.isNotEmpty
        ? DateFormat('yyyy-MM-dd - HH:mm:ss').format(DateTime.parse(deadlineRaw))
        : 'N/A';

    final pages = _pagesForRole();

    final bottomItems = _userRole == 'user'
        ? const [
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects'),
            BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Tracking'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ]
        : (_userRole == 'admin' || _userRole == 'officer')
            ? const [
                BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects'),
                BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Tracking'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
                BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Manage'),
              ]
            : const [
                BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects'),
                BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Tracking'),
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
              shadows: [Shadow(offset: Offset(4.0, 4.0), blurRadius: 1.5, color: Colors.white)],
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
              shadows: [Shadow(offset: Offset(4.0, 4.0), blurRadius: 1.5, color: Colors.white)],
            ),
          ),
        ),
      ]),
      displayName: isLoggedIn ? displayName : null,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomItems: bottomItems,
      currentIndex: (_selectedIndex < bottomItems.length) ? _selectedIndex : 0,
      onTap: (i) {
        if (i < pages.length) _onItemTapped(i);
      },
      floatingActionButton: _buildFab(),
    );
  }
}
