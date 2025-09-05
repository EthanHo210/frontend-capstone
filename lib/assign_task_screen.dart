// assign_task_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';

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

    // Extract leader
    _leaderUsername = (_project['leader'] ?? '').toString();
    _leaderFullName = _leaderUsername.isEmpty
        ? ''
        : (db.getUserByUsername(_leaderUsername)?['fullName'] ??
            db.getFullNameByUsername(_leaderUsername) ??
            _leaderUsername);

    // Parse members (String CSV or List), then keep only students for assignment
    List<String> rawMembers = [];
    if (_project.isNotEmpty && _project.containsKey('members')) {
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
    }

    // Students should only see their own team's students + leader (leader shown read-only)
    // Teachers/Admins also assign to students only (typical flow), but can view any team.
    final teamStudents = rawMembers.where((u) => db.isStudent(u)).toList();

    // Restrict visibility if viewer is a student: must be on the team
    if (_viewerRole == 'user') {
      final isOnTeam = rawMembers.contains(_viewerUsername);
      if (!isOnTeam) {
        // Block access if student tries to open a project they don't belong to
        Future.microtask(() => _showDenied());
        return;
      }
      _visibleAssignees = teamStudents;
    } else {
      // teacher/admin/officer (officer typically shouldn't reach here,
      // but if they do, still keep assignees = students of this project)
      _visibleAssignees = teamStudents;
    }
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
          'You are not a member of this project.',
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

  void _submitTask() {
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
          content:
              Text('Please add at least one subtask.', style: GoogleFonts.poppins()),
        ),
      );
      return;
    }

    _formKey.currentState?.save();

    try {
      final assigneeUsername = _assignedTo!.trim();

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

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Leader context (read-only; visible to everyone on the team)
            _buildLeaderChip(context),
            const SizedBox(height: 16),

            TextFormField(
              decoration: _buildInputDecoration('Task Title', context),
              style: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter task title' : null,
              onSaved: (value) => _taskTitle = value?.trim(),
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
                onChanged: (value) => setState(() => _assignedTo = value),
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
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add_circle, color: theme.colorScheme.primary),
                  onPressed: _addSubtask,
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
                    icon: Icon(Icons.delete, color: theme.colorScheme.error),
                    onPressed: () => _removeSubtask(idx),
                    tooltip: 'Remove subtask',
                  ),
                );
              }).toList(),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
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
    // If a student was denied in initState(), just render nothing while the dialog handles exit.
    if (_viewerRole == 'user' &&
        _project.isNotEmpty &&
        !_asSet((_project['members'])) .contains(_viewerUsername)) {
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
