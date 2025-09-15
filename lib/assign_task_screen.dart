// assign_task_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

class AssignTaskScreen extends StatefulWidget {
  final String projectName;
  final bool embedded;
  final void Function(bool created)? onCreated;

  const AssignTaskScreen({
    super.key,
    required this.projectName,
    this.embedded = false,
    this.onCreated,
  });

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final db = MockDatabase();
  final _formKey = GlobalKey<FormState>();

  String? _taskTitle;
  String? _assignedTo;
  final TextEditingController _subtaskController = TextEditingController();
  List<String> subtasks = [];

  // Members filtered to what the viewer is allowed to see (students only)
  late List<String> _visibleAssignees = [];

  // Current viewer
  late final String _viewerId;
  late final String _viewerUsername;
  late final String _viewerRole; // 'admin' | 'officer' | 'teacher' | 'user'

  // Project context
  Map<String, dynamic> _project = const {};
  String _leaderUsername = '';
  String _leaderFullName = '';

  // Snapshot of tasks for status/lock computation
  List<Map<String, dynamic>> _tasksSnapshot = const [];

  bool get _projectFound => _project.isNotEmpty;

  bool get _viewerIsLeader => _leaderUsername.isNotEmpty && _viewerUsername == _leaderUsername;

  bool get _canAssign =>
      _viewerRole == 'admin' ||
      _viewerRole == 'officer' ||
      _viewerRole == 'teacher' ||
      _viewerIsLeader;

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

    // --- who is viewing ---
    _viewerId = db.currentLoggedInUser ?? '';
    _viewerUsername = db.getUsernameByEmail(_viewerId) ?? _viewerId;
    _viewerRole = db.getUserRole(_viewerId);

    // --- load project + members safely ---
    final all = db.getAllProjects();
    _project = all.firstWhere(
      (p) => (p['name'] ?? '') == widget.projectName,
      orElse: () => <String, dynamic>{},
    );

    if (!_projectFound) {
      // Project not found → inform & close
      Future.microtask(() => _showErrorAndExit('Project "${widget.projectName}" was not found.'));
      return;
    }

    // Extract leader
    _leaderUsername = (_project['leader'] ?? '').toString();
    _leaderFullName = _leaderUsername.isEmpty
        ? ''
        : (db.getUserByUsername(_leaderUsername)?['fullName'] ??
            db.getFullNameByUsername(_leaderUsername) ??
            _leaderUsername);

    // Parse members (String CSV or List)
    List<String> rawMembers = [];
    final raw = _project['members'];
    if (raw is List) {
      rawMembers = raw.map((e) => e.toString()).toList();
    } else if (raw is String) {
      rawMembers = raw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Students only for assignment
    final teamStudents = rawMembers.where((u) => db.isStudent(u)).toList();

    // Restrict visibility if viewer is a student: must be on the team AND be the leader
    if (_viewerRole == 'user') {
      final isOnTeam = rawMembers.contains(_viewerUsername);
      if (!isOnTeam || !_viewerIsLeader) {
        // Block access if student not on team or not leader
        Future.microtask(() => _showDenied());
        return;
      }
      _visibleAssignees = teamStudents;
    } else {
      // teacher/admin/officer → assignees = students of this project
      _visibleAssignees = teamStudents;
    }

    // Auto-select when there's a single eligible assignee
    if (_visibleAssignees.length == 1) {
      _assignedTo = _visibleAssignees.first;
    }

    // Snapshot tasks for lock computation
    _tasksSnapshot = db.getTasksForProject(widget.projectName);
  }

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  void _showDenied() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Access Denied',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'You do not have permission to assign tasks for this project.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Close this screen if possible
              Navigator.maybePop(context);
              widget.onCreated?.call(false);
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
              widget.onCreated?.call(false);
            },
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTask() async {
    if (!_canAssign) {
      _showDenied();
      return;
    }

    if (_projectLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This project is locked (Completed/Overdue). New tasks cannot be assigned.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_visibleAssignees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No eligible members to assign this task.',
              style: GoogleFonts.poppins()),
        ),
      );
      return;
    }

    if (_assignedTo == null || _assignedTo!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a member to assign.',
              style: GoogleFonts.poppins()),
        ),
      );
      return;
    }

    if (subtasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least one subtask.', style: GoogleFonts.poppins()),
        ),
      );
      return;
    }

    _formKey.currentState?.save();

    final assigneeUsername = _assignedTo!.trim();
    final assigneeName =
        db.getUserByUsername(assigneeUsername)?['fullName'] ?? assigneeUsername;

    // 👉 Confirm dialog (client requirement)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final base = Theme.of(ctx);
        return Theme(
          data: base.copyWith(
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.button,
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.button,
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          child: AlertDialog(
            surfaceTintColor: Colors.transparent, // avoids grey overlay
            title: Text('Create Task', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            content: Text(
              'Assign "${_taskTitle?.trim() ?? ''}" to $assigneeName '
              '(${subtasks.length} subtask${subtasks.length == 1 ? '' : 's'})?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Confirm', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        );
      },
    ) ?? false;



    if (!confirmed) return;

    try {
      db.addTaskToProject(
        widget.projectName,
        title: (_taskTitle ?? '').trim(),
        assignedTo: assigneeUsername,
        subtasks: List<String>.from(subtasks),
      );

      // Embedded: notify parent & close
      if (widget.embedded) {
        widget.onCreated?.call(true);
        Navigator.maybePop(context);
        return;
      }

      // Standalone: pop back if we can
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
        return;
      }

      // Rare fallback: route to ProjectStatus
      final course = (db
                  .getAllProjects()
                  .firstWhere((p) => p['name'] == widget.projectName,
                      orElse: () => const {})['course'] ??
              'N/A')
          .toString();

      Navigator.pushReplacementNamed(
        context,
        '/projectStatus',
        arguments: {
          'projectName': widget.projectName,
          'courseName': course,
          'embedded': false,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create task: $e', style: GoogleFonts.poppins())),
      );
    }
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        subtasks.add(text);
        _subtaskController.clear();
      });
      FocusScope.of(context).unfocus();
    }
  }

  void _removeSubtask(int index) {
    setState(() {
      subtasks.removeAt(index);
    });
  }

  InputDecoration _buildInputDecoration(String label, BuildContext context) {
    final theme = Theme.of(context);
    final fill =
        theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.blue[50];

    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      filled: true,
      fillColor: fill,
    );
  }

  Widget _buildLeaderChip(BuildContext context) {
    if (_leaderUsername.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? Colors.white10 : Colors.black12;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, size: 18),
          const SizedBox(width: 8),
          Text(
            'Leader: $_leaderFullName (@$_leaderUsername)',
            style: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildLockBanner(BuildContext context) {
    if (!_projectLocked) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              'This project is locked (Completed or Overdue). Creating new tasks is disabled.',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            _buildLockBanner(context),

            // Leader context (read-only; visible to everyone on the team)
            _buildLeaderChip(context),
            const SizedBox(height: 16),

            TextFormField(
              decoration: _buildInputDecoration('Task Title', context),
              style: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter task title' : null,
              onSaved: (value) => _taskTitle = value?.trim(),
              enabled: !_projectLocked && _canAssign,
            ),
            const SizedBox(height: 20),

            if (_visibleAssignees.isEmpty) ...[
              Text(
                'No eligible members to assign this task.',
                style: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 20),
            ] else ...[
              DropdownButtonFormField<String>(
                decoration: _buildInputDecoration('Assign to', context),
                value: _assignedTo,
                items: _visibleAssignees.map((username) {
                  final name =
                      db.getUserByUsername(username)?['fullName'] ?? username;
                  return DropdownMenuItem(
                    value: username,
                    child: Text(
                      name,
                      style: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
                    ),
                  );
                }).toList(),
                validator: (value) => value == null ? 'Select a member' : null,
                onChanged: _projectLocked ? null : (value) => setState(() => _assignedTo = value),
                style: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
                dropdownColor: theme.colorScheme.surface,
              ),
              const SizedBox(height: 30),
            ],

            Text(
              'Add Subtasks:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskController,
                    decoration: _buildInputDecoration('Enter subtask', context),
                    style: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
                    onSubmitted: (_) => _addSubtask(),
                    enabled: !_projectLocked && _canAssign,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add_circle,
                      color: _projectLocked ? Colors.grey : theme.colorScheme.primary),
                  onPressed: _projectLocked ? null : _addSubtask,
                  tooltip: 'Add subtask',
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (subtasks.isNotEmpty)
              ...subtasks.asMap().entries.map((entry) {
                final idx = entry.key;
                final text = entry.value;
                return ListTile(
                  title: Text(
                    text,
                    style: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete,
                        color: _projectLocked ? Colors.grey : theme.colorScheme.error),
                    onPressed: _projectLocked ? null : () => _removeSubtask(idx),
                    tooltip: 'Remove subtask',
                  ),
                );
              }),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_projectLocked || !_canAssign) ? null : _submitTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  disabledBackgroundColor:
                      theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Create Task',
                  style: GoogleFonts.poppins(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If access was denied in initState(), render nothing while the dialog handles exit.
    if (!_projectFound || !_canAssign) {
      return const SizedBox.shrink();
    }

    final content = _buildContent(context);

    if (widget.embedded) {
      return SafeArea(top: false, bottom: false, child: content);
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task Assignment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: theme.colorScheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: content,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  // --- small helpers ---
  Set<String> _asSet(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toSet();
    } else if (raw is String) {
      return raw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
    }
    return {};
  }
}
