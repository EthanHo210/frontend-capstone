import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'mock_database.dart'; // Mock database for user authentication

class AdminMainHubScreen extends StatelessWidget {
  const AdminMainHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = MockDatabase();
    final role = db.getUserRole(db.currentLoggedInUser ?? '');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.blueText),
          tooltip: 'Back to Dashboard',
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/main_dashboard');
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'To',
              style: GoogleFonts.kavoon(
                textStyle: const TextStyle(
                  color: Colors.red,
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    Shadow(
                      offset: Offset(4.0, 4.0),
                      blurRadius: 1.5,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            Text(
              'gether!',
              style: GoogleFonts.kavoon(
                textStyle: const TextStyle(
                  color: Color.fromRGBO(42, 49, 129, 1),
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    Shadow(
                      offset: Offset(4.0, 4.0),
                      blurRadius: 1.5,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (role == 'admin') ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.people),
                label: const Text('Manage Users'),
                onPressed: () {
                  Navigator.pushNamed(context, '/manage_users');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueText,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
            ],
            ElevatedButton.icon(
              icon: const Icon(Icons.class_),
              label: const Text('Manage Courses'),
              onPressed: () {
                Navigator.pushNamed(context, '/manage_courses');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueText,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
