import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

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
          // back arrow stays brand blue
          icon: const Icon(Icons.arrow_back, color: AppColors.blueText),
          tooltip: 'Back to Dashboard',
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/main_dashboard');
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "To" part (red) — kept as red so logo looks the same in any theme
            Text(
              'To',
              style: GoogleFonts.kavoon(
                textStyle: TextStyle(
                  color: Colors.red,
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  shadows: const [
                    Shadow(
                      offset: Offset(4.0, 4.0),
                      blurRadius: 1.5,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            // "gether!" part — fixed to your brand blue so it doesn't change with theme
            Text(
              'gether!',
              style: GoogleFonts.kavoon(
                textStyle: TextStyle(
                  color: AppColors.blueText,
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  shadows: const [
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
                label: Text('Manage Users',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pushNamed(context, '/manage_users');
                },
                style: ElevatedButton.styleFrom(
                  // force brand blue button + white text/icon
                  backgroundColor: AppColors.blueText,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            ElevatedButton.icon(
              icon: const Icon(Icons.class_),
              label: Text('Manage Courses',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pushNamed(context, '/manage_courses');
              },
              style: ElevatedButton.styleFrom(
                // same fixed brand styling for this button too
                backgroundColor: AppColors.blueText,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
