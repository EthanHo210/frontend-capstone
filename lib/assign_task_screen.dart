import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task Assignment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppColors.blueText,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Task Title'),
                validator: (value) => value == null || value.isEmpty ? 'Enter task title' : null,
                onSaved: (value) => _taskTitle = value,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Assign to'),
                items: members.map((username) {
                  final name = db.getUserByUsername(username)?['fullName'] ?? username;
                  return DropdownMenuItem(value: username, child: Text(name));
                }).toList(),
                validator: (value) => value == null ? 'Select a member' : null,
                onChanged: (value) => setState(() => _assignedTo = value),
              ),
              const SizedBox(height: 30),
              const Text('Add Subtasks:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(hintText: 'Enter subtask'),
                      onChanged: (val) => _subtaskInput = val,
                      onSubmitted: (_) => _addSubtask(),
                      controller: TextEditingController(text: _subtaskInput),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.blueText),
                    onPressed: _addSubtask,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...subtasks.asMap().entries.map((entry) => ListTile(
                    title: Text(entry.value),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeSubtask(entry.key),
                    ),
                  )),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitTask,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueText),
                child: const Text('Create Task', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
