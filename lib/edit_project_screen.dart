import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

class EditProjectScreen extends StatefulWidget {
  final Map<String, String> project;

  const EditProjectScreen({super.key, required this.project});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  late TextEditingController _nameController;
  late TextEditingController _courseController;
  late TextEditingController _membersController;
  late DateTime _startDate;
  late DateTime _deadline;

  @override
  void initState() {
    super.initState();
    final role = MockDatabase().getUserRole(MockDatabase().currentLoggedInUser ?? '');
    if (role != 'teacher') {
      Future.microtask(() => _showUnauthorized());
    }
    _nameController = TextEditingController(text: widget.project['name']);
    _courseController = TextEditingController(text: widget.project['course']);
    _membersController = TextEditingController(text: widget.project['members']);
    _startDate = DateTime.tryParse(widget.project['startDate'] ?? '') ?? DateTime.now();
    _deadline = DateTime.tryParse(widget.project['deadline'] ?? '') ?? DateTime.now();
  }

  void _showUnauthorized() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: const Text('Only teachers are allowed to edit projects.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _deadline,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _deadline = picked;
        }
      });
    }
  }

  void _saveChanges() {
    final db = MockDatabase();
    final index = db.getAllProjects().indexWhere((p) => p['name'] == widget.project['name']);
    if (index != -1) {
      db.getAllProjects()[index] = {
        'name': _nameController.text,
        'course': _courseController.text,
        'members': _membersController.text,
        'startDate': _startDate.toIso8601String(),
        'deadline': _deadline.toIso8601String(),
        'status': db.calculateStatus(_deadline.toIso8601String(), 0),
      };
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.blueText),
        title: Text(
          'Edit Project',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppColors.blueText,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Project Name'),
            ),
            TextField(
              controller: _courseController,
              decoration: const InputDecoration(labelText: 'Course'),
            ),
            TextField(
              controller: _membersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of Members'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Start Date"),
              subtitle: Text("${_startDate.toLocal()}".split(' ')[0]),
              trailing: const Icon(Icons.calendar_today, color: AppColors.blueText),
              onTap: () => _pickDate(true),
            ),
            ListTile(
              title: const Text("Deadline"),
              subtitle: Text("${_deadline.toLocal()}".split(' ')[0]),
              trailing: const Icon(Icons.calendar_today, color: AppColors.blueText),
              onTap: () => _pickDate(false),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueText),
              child: const Text('Save Changes'),
            )
          ],
        ),
      ),
    );
  }
}
