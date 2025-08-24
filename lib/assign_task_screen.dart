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
  late List<String> members = [];

  @override
  void initState() {
    super.initState();

    // Safe project lookup and robust members parsing (String or List)
    final all = db.getAllProjects();
    final project = all.firstWhere((p) => p['name'] == widget.projectName, orElse: () => <String, dynamic>{});

    if (project.isNotEmpty && project.containsKey('members')) {
      final raw = project['members'];
      if (raw is List) {
        members = raw.map((e) => e.toString()).toList();
      } else if (raw is String) {
        members = raw
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }

    // Keep only student accounts (defensive)
    members = members.where((u) => db.isStudent(u)).toList();
  }

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  void _submitTask() {
    if ((_formKey.currentState?.validate() ?? false)) {
      if (subtasks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one subtask.')));
        return;
      }

      _formKey.currentState?.save();

      try {
        db.addTaskToProject(
          widget.projectName,
          title: _taskTitle!,
          assignedTo: _assignedTo!,
          subtasks: subtasks,
        );

        // If embedded: call callback + show snack and DO NOT pop the outer scaffold.
        if (widget.embedded) {
          widget.onCreated?.call(true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task created')));
        } else {
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create task: $e')));
      }
    }
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        subtasks.add(text);
        _subtaskController.clear();
      });
      FocusScope.of(context).requestFocus(FocusNode());
    }
  }

  void _removeSubtask(int index) {
    setState(() {
      subtasks.removeAt(index);
    });
  }

  InputDecoration _buildInputDecoration(String label, BuildContext context) {
    final theme = Theme.of(context);
    final fill = theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.blue[50];

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

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              decoration: _buildInputDecoration('Task Title', context),
              style: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
              validator: (value) => value == null || value.isEmpty ? 'Enter task title' : null,
              onSaved: (value) => _taskTitle = value?.trim(),
            ),
            const SizedBox(height: 20),

            if (members.isEmpty) ...[
              Text(
                'No eligible members to assign this task.',
                style: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 20),
            ] else ...[
              DropdownButtonFormField<String>(
                decoration: _buildInputDecoration('Assign to', context),
                value: _assignedTo,
                items: members.map((username) {
                  final name = db.getUserByUsername(username)?['fullName'] ?? username;
                  return DropdownMenuItem(
                    value: username,
                    child: Text(name, style: GoogleFonts.poppins(color: theme.colorScheme.onSurface)),
                  );
                }).toList(),
                validator: (value) => value == null ? 'Select a member' : null,
                onChanged: (value) => setState(() => _assignedTo = value),
                style: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
                dropdownColor: theme.colorScheme.surface,
              ),
              const SizedBox(height: 30),
            ],

            Text('Add Subtasks:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
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

            if (subtasks.isNotEmpty) ...subtasks.asMap().entries.map((entry) {
              final idx = entry.key;
              final text = entry.value;
              return ListTile(
                title: Text(text, style: GoogleFonts.poppins(color: theme.colorScheme.onSurface)),
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
    final content = _buildContent(context);

    if (widget.embedded) {
      // content-only; keep parent chrome; avoid extra paddings
      return SafeArea(top: false, bottom: false, child: content);
    }

    // standalone route
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

}
