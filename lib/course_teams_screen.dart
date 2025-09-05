import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'app_colors.dart';
import 'mock_database.dart';
import 'dashboard_scaffold.dart';
import 'route_observer.dart'; // ⬅️ NEW: for RouteAware refresh

class CourseTeamsScreen extends StatefulWidget {
  /// Can be a course **name** or **id**. We’ll resolve either.
  final String selectedCourse;
  final bool embedded;
  final void Function(String projectName, String courseName)? onOpenProject;
  final VoidCallback? onStartNewProject;
  final VoidCallback? onBack;

  const CourseTeamsScreen({
    super.key,
    required this.selectedCourse,
    this.embedded = false,
    this.onOpenProject,
    this.onStartNewProject,
    this.onBack,
  });

  @override
  State<CourseTeamsScreen> createState() => _CourseTeamsScreenState();
}

class _CourseTeamsScreenState extends State<CourseTeamsScreen> with RouteAware {
  final db = MockDatabase();

  // Projects shown on this course
  List<Map<String, dynamic>> projects = [];

  // User
  late String currentUser;   // may be email or username
  late String username;      // normalized username
  late String fullName;
  late String userRole;

  // Course meta (rich model)
  Map<String, dynamic>? _course;  // resolved record
  String get _courseName => (_course?['name'] ?? widget.selectedCourse).toString();
  String? get _courseId => _course?['id']?.toString();

  @override
  void initState() {
    super.initState();
    currentUser = db.currentLoggedInUser ?? '';
    username = db.getUsernameByEmail(currentUser) ?? currentUser;
    fullName = db.getFullNameByUsername(username) ?? username;
    userRole = db.getUserRole(currentUser);

    _resolveCourse();
    _loadProjects();
  }

  // ⬇️ NEW: subscribe to route observer so when we pop back here, we reload.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Called when a pushed route above this one is popped (we returned here)
  @override
  void didPopNext() {
    _resolveCourse();
    _loadProjects();
  }
  // ⬆️ NEW

  @override
  void didUpdateWidget(covariant CourseTeamsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCourse != widget.selectedCourse) {
      _resolveCourse();
      _loadProjects();
    }
  }

  // Accept either id or name, prefer id match when available
  void _resolveCourse() {
    // Try id first
    final byId = db.getCourseById(widget.selectedCourse);
    if (byId != null) {
      setState(() => _course = Map<String, dynamic>.from(byId));
      return;
    }
    // Then by name (case-insensitive)
    final byName = db.getCourseByName(widget.selectedCourse);
    if (byName != null) {
      setState(() => _course = Map<String, dynamic>.from(byName));
      return;
    }
    // Fallback (legacy/course removed): just synthesize a name record
    setState(() => _course = {
      'id': null,
      'name': widget.selectedCourse,
      'semester': 'N/A',
      'campus': 'N/A',
      'lecturers': const <String>[],
      'students': const <String>[],
    });
  }

  void _loadProjects() {
    final allProjects = db.getAllProjects();

    final filtered = allProjects.where((project) {
      // Prefer matching by courseId if present on the project and we have one
      final projCourseId = (project['courseId'] ?? '').toString();
      if (_courseId != null && _courseId!.isNotEmpty) {
        if (projCourseId != _courseId) return false;
      } else {
        // Fallback: match by name
        final courseName = (project['course'] ?? 'N/A').toString();
        if (courseName != _courseName) return false;
      }

      // Only show projects the user can see:
      // - admins/officers/teachers see all
      // - users must be a member of the project
      if (userRole == 'admin' || userRole == 'officer' || userRole == 'teacher') return true;

      final rawMembers = project['members'];
      final members = _parseMemberList(rawMembers);
      return members.contains(username);
    }).toList();

    setState(() {
      projects = List<Map<String, dynamic>>.from(filtered);
    });
  }

  List<String> _parseMemberList(dynamic rawMembers) {
    if (rawMembers == null) return <String>[];
    if (rawMembers is String) {
      return rawMembers
          .split(',')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList();
    }
    if (rawMembers is List) {
      return rawMembers.map((e) => e.toString()).toList();
    }
    return <String>[];
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

  Map<String, dynamic>? _projectForTracking() {
    if (projects.isEmpty) return null;
    final copy = [...projects];
    copy.sort((a, b) {
      final aDt = DateTime.tryParse((a['startDate'] ?? '').toString()) ?? DateTime(1970);
      final bDt = DateTime.tryParse((b['startDate'] ?? '').toString()) ?? DateTime(1970);
      return bDt.compareTo(aDt);
    });
    return copy.first;
  }

  // --- single place to start a new project (enables the button) ---
  Future<void> _handleStartNewProject() async { // ⬅️ made async
    if (!(userRole == 'admin' || userRole == 'officer' || userRole == 'teacher')) return;

    // Prefer the embedded callback if parent provided it
    if (widget.onStartNewProject != null) {
      widget.onStartNewProject!();
      return;
    }

    // Fallback: use the existing named route, refresh when coming back
    await Navigator.pushNamed(context, '/start_new_project'); // ⬅️ await
    if (mounted) _loadProjects(); // ⬅️ refresh
  }

  // ---------- UI bits ----------

  Widget _courseHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = Theme.of(context).textTheme.bodyLarge?.color;
    final bodyColor  = Theme.of(context).textTheme.bodyMedium?.color;
    final chipBg = isDark ? AppColors.blueText.withOpacity(0.10) : Colors.blue[50];

    // Pull lecturers/students from rich model (works with id or name)
    final lecturers = db.getLecturersForCourse(_courseId ?? _courseName);
    final students  = db.getStudentsForCourse(_courseId ?? _courseName);

    final semester = (_course?['semester'] ?? 'N/A').toString();
    final campus   = (_course?['campus'] ?? 'N/A').toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        color: isDark ? AppColors.blueText.withOpacity(0.08) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Course name + quick actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _courseName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ),
                  if (userRole == 'admin' || userRole == 'officer' || userRole == 'teacher')
                    IconButton(
                      tooltip: 'Manage Courses',
                      icon: const Icon(Icons.manage_accounts, color: AppColors.blueText),
                      onPressed: () {
                        Navigator.pushNamed(context, '/manage_courses');
                      },
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Semester: $semester • Campus: $campus',
                style: GoogleFonts.poppins(fontSize: 12, color: bodyColor),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: -6,
                children: [
                  Chip(
                    label: Text('Lecturers: ${lecturers.length}'),
                    backgroundColor: chipBg,
                  ),
                  Chip(
                    label: Text('Students: ${students.length}'),
                    backgroundColor: chipBg,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (userRole == 'admin' || userRole == 'officer' || userRole == 'teacher')
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _handleStartNewProject,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text('Create Project',
                        style: GoogleFonts.poppins(color: Colors.white)),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.button,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = textTheme.bodyLarge?.color;
    final bodyColor  = textTheme.bodyMedium?.color;

    final header = _courseHeader(context);

    if (projects.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.embedded && widget.onBack != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to courses',
                onPressed: widget.onBack,
              ),
            ),
          header,
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open, size: 64, color: textTheme.bodyLarge?.color),
                  const SizedBox(height: 12),
                  Text(
                    'No projects available in this course.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // 👇 intentionally no extra Create button here
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.embedded && widget.onBack != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to courses',
              onPressed: widget.onBack,
            ),
          ),
        header,
        const SizedBox(height: 8),

        // Project list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              final name = (project['name'] ?? 'Unknown').toString();
              final courseShown = _courseName;
              final status = (project['status'] ?? 'Unknown').toString();
              final startDateFormatted = _formatDate(project['startDate']);
              final deadlineFormatted = _formatDate(project['deadline']);

              final memberIds = _parseMemberList(project['members']);
              final memberNames = memberIds.map((id) {
                final full = db.getFullNameByUsername(id) ?? id;
                return full.isNotEmpty
                    ? '${full[0].toUpperCase()}${full.substring(1)}'
                    : id;
              }).toList();

              final leaderUser = (project['leader'] ?? '').toString();
              final leaderName = leaderUser.isEmpty
                  ? '—'
                  : (db.getFullNameByUsername(leaderUser) ?? leaderUser);

              final canSeeNames =
                  (userRole == 'admin' || userRole == 'officer' || userRole == 'teacher') ||
                  memberIds.contains(username);

              return Card(
                color: isDark ? AppColors.blueText.withOpacity(0.10) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Course: $courseShown',
                          style: GoogleFonts.poppins(fontSize: 14, color: bodyColor)),
                      const SizedBox(height: 4),
                      Text('Start Date: $startDateFormatted\nDeadline: $deadlineFormatted',
                          style: GoogleFonts.poppins(fontSize: 12, color: bodyColor)),
                      const SizedBox(height: 4),
                      Text('Status: $status',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: getStatusColor(status),
                          )),
                      const SizedBox(height: 6),
                      Text(
                        'Leader: $leaderName',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (canSeeNames && memberNames.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (memberIds.contains(username) && userRole == 'user')
                                  ? 'Your Team:'
                                  : 'Team Members:',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: titleColor,
                              ),
                            ),
                            ...memberNames.map((n) => Text(
                                  '- $n',
                                  style: GoogleFonts.poppins(fontSize: 12, color: titleColor),
                                )),
                          ],
                        ),
                    ],
                  ),
                  trailing: (userRole == 'admin' || userRole == 'officer' || userRole == 'teacher')
                      ? IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.blueText),
                          tooltip: 'Edit Project',
                          onPressed: () async {
                            final updated = await Navigator.pushNamed(
                              context,
                              '/edit_project',
                              arguments: Map<String, dynamic>.from(project),
                            );
                            if (updated != null) _loadProjects();
                          },
                        )
                      : null,
                  onTap: () {
                    if (widget.embedded) {
                      widget.onOpenProject?.call(name, courseShown);
                      return;
                    }
                    Navigator.pushNamed(
                      context,
                      '/projectStatus',
                      arguments: {
                        'projectName': name,
                        'courseName': courseShown,
                      },
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

  List<BottomNavigationBarItem> _navItemsForRole() {
    if (userRole == 'admin' || userRole == 'officer') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline), label: 'Start New'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects'),
        BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Tracking'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Manage'),
      ];
    } else if (userRole == 'teacher') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline), label: 'Start New'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects'),
        BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Tracking'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects'),
        BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Tracking'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ];
    }
  }

  int _projectsTabIndex() {
    if (userRole == 'admin' || userRole == 'officer' || userRole == 'teacher') {
      return 1; // StartNew, Projects, ...
    }
    return 0; // user: Projects is first
  }

  void _handleTap(int index) {
    if (userRole == 'admin' || userRole == 'officer') {
      switch (index) {
        case 0:
          Navigator.pushNamed(context, '/start_new_project')
              .then((_) => _loadProjects()); // ⬅️ refresh after return
          break;
        case 1:
          break;
        case 2:
          final p = _projectForTracking();
          if (p == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No project to track')),
            );
            return;
          }
          Navigator.pushNamed(
            context,
            '/projectStatus',
            arguments: {
              'projectName': (p['name'] ?? '').toString(),
              'courseName': _courseName,
            },
          );
          break;
        case 3:
          Navigator.pushNamed(context, '/settings');
          break;
        case 4:
          Navigator.pushReplacementNamed(context, '/dashboard');
          break;
      }
    } else if (userRole == 'teacher') {
      switch (index) {
        case 0:
          Navigator.pushNamed(context, '/start_new_project')
              .then((_) => _loadProjects()); // ⬅️ refresh after return
          break;
        case 1:
          break;
        case 2:
          final p = _projectForTracking();
          if (p == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No project to track')),
            );
            return;
          }
          Navigator.pushNamed(
            context,
            '/projectStatus',
            arguments: {
              'projectName': (p['name'] ?? '').toString(),
              'courseName': _courseName,
            },
          );
          break;
        case 3:
          Navigator.pushNamed(context, '/settings');
          break;
      }
    } else {
      switch (index) {
        case 0:
          break;
        case 1:
          final p = _projectForTracking();
          if (p == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You are not in any project')),
            );
            return;
          }
          Navigator.pushNamed(
            context,
            '/projectStatus',
            arguments: {
              'projectName': (p['name'] ?? '').toString(),
              'courseName': _courseName,
            },
          );
          break;
        case 2:
          Navigator.pushNamed(context, '/settings');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.embedded) return body;

    final titleWidget = Row(mainAxisSize: MainAxisSize.min, children: [
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
    ]);

    return DashboardScaffold(
      appBarTitle: titleWidget,
      displayName: fullName,
      body: body,
      bottomItems: _navItemsForRole(),
      currentIndex: _projectsTabIndex(),
      onTap: _handleTap,
    );
  }
}
