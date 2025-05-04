import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';

class StartNewProjectScreen extends StatefulWidget {
  const StartNewProjectScreen({super.key});

  @override
  State<StartNewProjectScreen> createState() => _StartNewProjectScreenState();
}

class _StartNewProjectScreenState extends State<StartNewProjectScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _membersController = TextEditingController();
  final TextEditingController _courseNameController = TextEditingController();
  DateTime? _deadline;

  void _submitProject() {
    final name = _nameController.text.trim();
    final members = _membersController.text.trim();
    final courseName = _courseNameController.text.trim();

    if (name.isEmpty || members.isEmpty || courseName.isEmpty || _deadline == null) {
      _showError('All fields are required, including the deadline.');
      return;
    }

    if (int.tryParse(members) == null) {
      _showError('Number of users has to be a number.');
      return;
    }

    if (int.parse(members) < 1) {
      _showError('Number of users has to be at least 1.');
      return;
    }   
    
    final formattedDeadline = _deadline!.toIso8601String();

    MockDatabase().addProject({
      'name': name,
      'members': members,
      'startDate': DateTime.now().toIso8601String(),
      'deadline': formattedDeadline,
      'course': courseName,
    });

    Navigator.pop(context);
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Input Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Start Your Project',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputField(_nameController, 'Group Name'),
            const SizedBox(height: 16),
            _buildInputField(_courseNameController, 'Course Name'),
            const SizedBox(height: 16),
            _buildInputField(_membersController, 'Number of Group Members'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.teal),
                const SizedBox(width: 12),
                Text(
                  _deadline != null
                      ? 'Deadline: ${_deadline!.toLocal().toString().split(' ')[0]}'
                      : 'Pick Project Deadline',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.date_range, color: Colors.teal),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _deadline = picked);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'CONFIRM',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hintText) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.green[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
