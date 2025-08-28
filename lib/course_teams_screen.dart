import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'app_colors.dart';
import 'mock_database.dart';
import 'dashboard_scaffold.dart';

class CourseTeamsScreen extends StatefulWidget {
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

class _CourseTeamsScreenState extends State<CourseTeamsScreen> {
  final db = MockDatabase();
  List<Map<String, dynamic>> projects = [];
  late String currentUser;
  late String username;
  late String fullName;
  late String userRole;

  @override
  void initState() {
    super.initState();
    currentUser = db.currentLoggedInUser ?? '';
    username = db.getUsernameByEmail(currentUser) ?? currentUser;
    fullName = db.getFullNameByUsername(username) ?? username;
    userRole = db.getUserRole(currentUser);
    _loadProjects();
  }

  // 🔧 IMPORTANT: reload when the parent changes the selected course
  @override
  void didUpdateWidget(covariant CourseTeamsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCourse != widget.selectedCourse) {
      _loadProjects();
    }
  }

  void _loadProjects() {
    final allProjects = db.getAllProjects();

    final filtered = allProjects.where((project) {
      final course = (project['course'] ?? 'N/A').toString();
      if (course != widget.selectedCourse) return false;

      final rawMembers = project['members'];
      final members = _parseMemberList(rawMembers);

      return members.contains(username) ||
          userRole == 'admin' ||
          userRole == 'officer';
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
    // Prefer most recent by startDate if present; otherwise just first.
    final copy = [...projects];
    copy.sort((a, b) {
      final aDt = DateTime.tryParse((a['startDate'] ?? '').toString()) ?? DateTime(1970);
      final bDt = DateTime.tryParse((b['startDate'] ?? '').toString()) ?? DateTime(1970);
      return bDt.compareTo(aDt);
    });
    return copy.first;
  }

  Widget _buildBody(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = Theme.of(context).textTheme.bodyLarge?.color;
    final bodyColor  = Theme.of(context).textTheme.bodyMedium?.color;

    if (projects.isEmpty) {
      return Center(
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
            const SizedBox(height: 8),
            if (userRole == 'admin' || userRole == 'officer' || userRole == 'teacher')
              ElevatedButton(
                onPressed: () => widget.onStartNewProject?.call(),
                child: Text('Create Project', style: GoogleFonts.poppins()),
              ),
          ],
        ),
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
        
        const SizedBox(height: 8),

        // the list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              final name = (project['name'] ?? 'Unknown').toString();
              final course = (project['course'] ?? 'N/A').toString();
              final status = (project['status'] ?? 'Unknown').toString();
              final startDateFormatted = _formatDate(project['startDate']);
              final deadlineFormatted = _formatDate(project['deadline']);

              final memberIds = _parseMemberList(project['members']);
              final studentNames = memberIds.map((id) {
                final full = db.getFullNameByUsername(id) ?? id;
                return full.isNotEmpty
                    ? '${full[0].toUpperCase()}${full.substring(1)}'
                    : id;
              }).toList();

              return Card(
                color: isDark ? AppColors.blueText.withOpacity(0.10) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 16, color: titleColor)),
                      const SizedBox(height: 4),
                      Text('Course: $course',
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
                      if (studentNames.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Students:',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600, fontSize: 13, color: titleColor)),
                            ...studentNames.map((n) => Text('- $n',
                                style: GoogleFonts.poppins(fontSize: 12, color: titleColor))),
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
                    // When embedded, ALWAYS use the embedded callback so we don't push a new route
                    // (prevents ProjectStatusScreen from showing its own AppBar).
                    if (widget.embedded) {
                      widget.onOpenProject?.call(name, course);
                      return;
                    }

                    // Standalone fallback only when not embedded
                    Navigator.pushNamed(
                      context,
                      '/projectStatus',
                      arguments: {'projectName': name, 'courseName': course},
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
          Navigator.pushNamed(context, '/start_new_project');
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
              'courseName': (p['course'] ?? '').toString(),
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
          Navigator.pushNamed(context, '/start_new_project');
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
              'courseName': (p['course'] ?? '').toString(),
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
              'courseName': (p['course'] ?? '').toString(),
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
      appBarTitle: titleWidget,       // shows the Together! title
      displayName: fullName,
      body: body,                     // <- your _buildBody(context)
      bottomItems: _navItemsForRole(),
      currentIndex: _projectsTabIndex(),
      onTap: _handleTap,
    );

  }

}
