import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Project Leader Assignment',
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: memberUsernames.length,
        itemBuilder: (_, index) {
          final username = memberUsernames[index];
          final fullName = db.getUserByUsername(username)?['fullName'] ?? username;
          final isSelected = username == selectedLeader;

          return ListTile(
            title: Text(fullName),
            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Leader Assignment"),
                  content: Text("Are you sure you want to assign $fullName as the group leader?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        assignLeader(username);
                        Navigator.pop(context); // Close dialog
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueText),
                      child: const Text("Confirm", style: TextStyle(color: Colors.white)),
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
