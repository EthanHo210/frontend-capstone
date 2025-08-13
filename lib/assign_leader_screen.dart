import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';

class AssignLeaderScreen extends StatefulWidget {
  final String projectName;
  const AssignLeaderScreen({super.key, required this.projectName});

  @override
  State<AssignLeaderScreen> createState() => _AssignLeaderScreenState();
}

class _AssignLeaderScreenState extends State<AssignLeaderScreen> {
  final db = MockDatabase();
  late List<String> memberUsernames;
  String? selectedLeader;

  @override
  void initState() {
    super.initState();
    final project = db.getAllProjects().firstWhere((p) => p['name'] == widget.projectName);
    memberUsernames = List<String>.from(project['members']);
    // Only keep students
    memberUsernames = memberUsernames.where((u) => db.isStudent(u)).toList();
    selectedLeader = db.getProjectLeader(widget.projectName);
  }

  void assignLeader(String username) {
    db.assignLeader(widget.projectName, username);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Project Leader Assignment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: colorScheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: memberUsernames.length,
        itemBuilder: (_, index) {
          final username = memberUsernames[index];
          final fullName = db.getUserByUsername(username)?['fullName'] ?? username;
          final isSelected = username == selectedLeader;

          return ListTile(
            title: Text(fullName, style: TextStyle(color: colorScheme.onBackground)),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: colorScheme.secondary)
                : null,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    "Confirm Leader Assignment",
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  content: Text(
                    "Are you sure you want to assign $fullName as the group leader?",
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  backgroundColor: colorScheme.surface,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel", style: TextStyle(color: colorScheme.primary)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        assignLeader(username);
                        Navigator.pop(context); // Close dialog
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
          );
        },
      ),
    );
  }
}
