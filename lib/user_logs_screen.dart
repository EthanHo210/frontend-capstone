import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

class UserLogsScreen extends StatelessWidget {
  const UserLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = MockDatabase();
    final currentUser = db.currentLoggedInUser ?? '';
    final isTeacher = db.isTeacher(currentUser);
    final users = db.getAllUsers().where((user) => user['username'] != 'admin').toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.blueText),
        title: Text(
          isTeacher ? 'Member Logs' : 'User Directory',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.blueText,
          ),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final username = user['username'];
          final role = user['role'];

          // Skip teachers on teacher view (they don't need a log), skip all except students and teachers on student view
          if (isTeacher && role == 'teacher') return const SizedBox.shrink();
          if (!isTeacher && role != 'teacher' && role != 'user') return const SizedBox.shrink();

          final projectInfo = db.getProjectInfoForUser(username);

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.blue[50],
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isTeacher
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blueText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Project team: ${projectInfo?['project'] ?? 'N/A'}', style: GoogleFonts.poppins()),
                        Text('Project status: ${projectInfo?['rank'] ?? 'N/A'}', style: GoogleFonts.poppins()),
                        Text('Assigned task: (Coming soon)', style: GoogleFonts.poppins()),
                        Text('Contribution rate: ${projectInfo?['contribution'] ?? '0%'}', style: GoogleFonts.poppins()),
                        Text('Comment: (Coming soon)', style: GoogleFonts.poppins()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blueText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Email: ${user['email']}', style: GoogleFonts.poppins()),
                        Text('Role: ${user['role']}', style: GoogleFonts.poppins()),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
