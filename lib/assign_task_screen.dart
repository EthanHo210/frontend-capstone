import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';

class AssignTaskScreen extends StatefulWidget {
  final String projectName;

  const AssignTaskScreen({super.key, required this.projectName});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final db = MockDatabase();
  final _formKey = GlobalKey<FormState>();
  String? _taskTitle;
  String? _assignedTo;
  String _subtaskInput = '';
  List<String> subtasks = [];
  late List<String> members;

  @override
  void initState() {
    super.initState();
    final project = db.getAllProjects().firstWhere((p) => p['name'] == widget.projectName);
    members = List<String>.from(project['members']);
    members = members.where((u) => db.isStudent(u)).toList();
  }

  void _submitTask() {
    if ((_formKey.currentState?.validate() ?? false) && subtasks.isNotEmpty) {
      _formKey.currentState?.save();
      db.addTaskToProject(
        widget.projectName,
        title: _taskTitle!,
        assignedTo: _assignedTo!,
        subtasks: subtasks,
      );
      Navigator.pop(context);
    }
  }

  void _addSubtask() {
    if (_subtaskInput.trim().isNotEmpty) {
      setState(() {
        subtasks.add(_subtaskInput.trim());
        _subtaskInput = '';
      });
    }
  }

  void _removeSubtask(int index) {
    setState(() {
      subtasks.removeAt(index);
    });
  }

  InputDecoration _buildInputDecoration(String label, BuildContext context) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant,
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: _buildInputDecoration('Task Title', context),
                style: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
                validator: (value) => value == null || value.isEmpty ? 'Enter task title' : null,
                onSaved: (value) => _taskTitle = value,
              ),
              const SizedBox(height: 20),
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
                      decoration: _buildInputDecoration('Enter subtask', context),
                      style: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
                      onChanged: (val) => _subtaskInput = val,
                      onSubmitted: (_) => _addSubtask(),
                      controller: TextEditingController(text: _subtaskInput),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: theme.colorScheme.primary),
                    onPressed: _addSubtask,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...subtasks.asMap().entries.map((entry) => ListTile(
                    title: Text(
                      entry.value,
                      style: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: theme.colorScheme.error),
                      onPressed: () => _removeSubtask(entry.key),
                    ),
                  )),
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
      ),
    );
  }
}
