// admin_main_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

/// Content-only Admin hub — NO Scaffold / NO AppBar.
/// The parent (MainDashboard) should render the app's AppBar + BottomNav.
/// onNavigate receives action keys like 'manage_users' or 'manage_courses'.
class AdminMainHubScreen extends StatelessWidget {
  final void Function(String action)? onNavigate;

  const AdminMainHubScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final db = MockDatabase();
    final role = db.getUserRole(db.currentLoggedInUser ?? '');

    Widget buildButton({
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
    }) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(icon),
          label: Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blueText,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            minimumSize: const Size.fromHeight(56),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // Only admins see the Manage Users button
          if (role == 'admin') ...[
            buildButton(
              icon: Icons.people,
              label: 'Manage Users',
              onPressed: () {
                // Prefer parent callback (embedded navigation); fallback to route push
                if (onNavigate != null) {
                  onNavigate!('manage_users');
                } else {
                  Navigator.pushNamed(context, '/manage_users');
                }
              },
            ),
            const SizedBox(height: 24),
          ],

          // Manage Courses available to admins/officers
          buildButton(
            icon: Icons.class_,
            label: 'Manage Courses',
            onPressed: () {
              if (onNavigate != null) {
                onNavigate!('manage_courses');
              } else {
                Navigator.pushNamed(context, '/manage_courses');
              }
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
