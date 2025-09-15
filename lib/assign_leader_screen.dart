// assign_leader_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

class AssignLeaderScreen extends StatefulWidget {
  final String projectName;

  /// set to true when you want this widget embedded in another Scaffold/IndexedStack
  final bool embedded;

  /// optional callback invoked when a leader is assigned (useful for embedded mode)
  final void Function(String username)? onAssigned;

  const AssignLeaderScreen({
    super.key,
    required this.projectName,
    this.embedded = false,
    this.onAssigned,
  });

  @override
  State<AssignLeaderScreen> createState() => _AssignLeaderScreenState();
}

class _AssignLeaderScreenState extends State<AssignLeaderScreen> {
  final db = MockDatabase();

  // viewer context
  late final String _viewerId;
  late final String _viewerUsername;
  late final String _viewerRole; // 'admin' | 'officer' | 'teacher' | 'user'

  // project context
  Map<String, dynamic> _project = const {};
  List<String> _memberUsernames = [];
  String? _selectedLeader;

  // snapshot for lock computation
  List<Map<String, dynamic>> _tasksSnapshot = const [];

  bool _loading = true;

  bool get _projectFound => _project.isNotEmpty;

  bool get _canAssignLeader =>
      _viewerRole == 'admin' || _viewerRole == 'officer' || _viewerRole == 'teacher';

  double _computeCompletionPct() {
    if (_tasksSnapshot.isEmpty) return 0;
    final confirmed = _tasksSnapshot.where((task) {
      final subtasks = (task['subtasks'] ?? []) as List<dynamic>;
      if (subtasks.isEmpty) return false;
      final approvedCount = subtasks.where((s) => s['status'] == 'Approved').length;
      return approvedCount == subtasks.length;
    }).length;
    return (confirmed / _tasksSnapshot.length) * 100;
  }

  bool get _projectLocked {
    if (!_projectFound) return false;
    final deadline = (_project['deadline'] ?? '').toString();
    if (deadline.isEmpty) return false;
    final completion = _computeCompletionPct().round();
    final status = db.calculateStatus(deadline, completion);
    return status == 'Completed' || status == 'Overdue';
  }

  @override
  void initState() {
    super.initState();

    // viewer
    _viewerId = db.currentLoggedInUser ?? '';
    _viewerUsername = db.getUsernameByEmail(_viewerId) ?? _viewerId;
    _viewerRole = db.getUserRole(_viewerId);

    // project
    final all = db.getAllProjects();
    _project = all.firstWhere(
      (p) => (p['name'] ?? '') == widget.projectName,
      orElse: () => <String, dynamic>{},
    );

    if (!_projectFound) {
      Future.microtask(() => _showErrorAndExit('Project "${widget.projectName}" was not found.'));
      return;
    }

    // members -> students only
    List<String> members = [];
    final raw = _project['members'];
    if (raw is List) {
      members = raw.map((e) => e.toString()).toList();
    } else if (raw is String) {
      members = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    _memberUsernames = members.where((u) => db.isStudent(u)).toList();

    _selectedLeader = db.getProjectLeader(widget.projectName);

    // snapshot tasks to compute lock state
    _tasksSnapshot = db.getTasksForProject(widget.projectName);

    // access: only teacher/admin/officer can be here
    if (!_canAssignLeader) {
      Future.microtask(() => _showDenied(
            'You do not have permission to assign a leader for this project.',
          ));
      return;
    }

    setState(() => _loading = false);
  }

  void _showDenied(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Access Denied', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(msg, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.maybePop(context);
              widget.onAssigned?.call('');
            },
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showErrorAndExit(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(msg, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.maybePop(context);
              widget.onAssigned?.call('');
            },
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _assignLeader(String username) {
    if (_projectLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This project is locked (Completed/Overdue). Leader changes are disabled.',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    db.assignLeader(widget.projectName, username);
    if (mounted) setState(() => _selectedLeader = username);
  }

  Widget _lockBanner() {
    if (!_projectLocked) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This project is locked (Completed or Overdue). Assigning a leader is disabled.',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_memberUsernames.isEmpty) {
      return Center(
        child: Text('No eligible students found in this project.',
            style: GoogleFonts.poppins(fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _memberUsernames.length,
      itemBuilder: (_, index) {
        final username = _memberUsernames[index];
        final fullName = db.getUserByUsername(username)?['fullName'] ?? username;
        final isSelected = username == _selectedLeader;

        return Card(
          child: ListTile(
            title: Text(fullName, style: GoogleFonts.poppins(color: colorScheme.onSurface)),
            trailing: isSelected ? Icon(Icons.check_circle, color: colorScheme.secondary) : null,
            enabled: !_projectLocked,
            onTap: _projectLocked
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Confirm Leader Assignment",
                            style: GoogleFonts.poppins(color: colorScheme.onSurface)),
                        content: Text(
                          "Are you sure you want to assign $fullName as the group leader?",
                          style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant),
                        ),
                        backgroundColor: Theme.of(context).dialogBackgroundColor,
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Cancel", style: TextStyle(color: colorScheme.primary)),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              _assignLeader(username);
                              Navigator.pop(context); // close dialog

                              // If this screen is on the stack, pop it and let ProjectStatus.didPopNext() refresh.
                              if (Navigator.canPop(context) && !widget.embedded) {
                                Navigator.pop(context, true);
                                return;
                              }

                              // Pure embedded: notify parent + toast
                              widget.onAssigned?.call(username);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("$fullName assigned as leader",
                                      style: GoogleFonts.poppins()),
                                  backgroundColor: AppColors.blueText,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                            ),
                            child: const Text("Confirm"),
                          ),
                        ],
                      ),
                    );
                  },
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_projectFound) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        _lockBanner(),
        Expanded(child: _buildList(context)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return SafeArea(top: false, bottom: false, child: _buildContent(context));
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Project Leader Assignment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22, color: colorScheme.primary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: _buildContent(context),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}
