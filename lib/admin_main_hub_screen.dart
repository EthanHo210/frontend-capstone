// admin_main_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'mock_database.dart';

/// Content-only Admin hub — NO Scaffold / NO AppBar.
/// The parent (MainDashboard) renders the app's AppBar + BottomNav.
/// onNavigate receives action keys like 'manage_users' or 'manage_courses'.
class AdminMainHubScreen extends StatelessWidget {
  final void Function(String action)? onNavigate;

  const AdminMainHubScreen({super.key, this.onNavigate});

  ButtonStyle _primaryBtnStyle(BuildContext context) => ElevatedButton.styleFrom(
        backgroundColor: AppColors.button,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size.fromHeight(56),
      );

  @override
  Widget build(BuildContext context) {
    final db = MockDatabase();
    final role = db.getUserRole(db.currentLoggedInUser ?? '');
    final titleColor =
        Theme.of(context).textTheme.titleLarge?.color ?? Theme.of(context).colorScheme.onSurface;

    Widget buildButton({
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
    }) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(icon),
          label: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          onPressed: onPressed,
          style: _primaryBtnStyle(context),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Admin Hub',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 16),

          // Only admins see the Manage Users button
          if (role == 'admin') ...[
            buildButton(
              icon: Icons.people,
              label: 'Manage Users',
              onPressed: () {
                if (onNavigate != null) {
                  onNavigate!('manage_users');
                } else {
                  Navigator.pushNamed(context, '/manage_users');
                }
              },
            ),
            const SizedBox(height: 16),
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
        ],
      ),
    );
  }
}
