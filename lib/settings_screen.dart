import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

class SettingsScreen extends StatelessWidget {
  final bool isAdmin;

  const SettingsScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final db = MockDatabase();
    final role = db.getUserRole(db.currentLoggedInUser ?? '');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.blueText,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.blueText),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Account',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.blueText,
            ),
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context,
            icon: Icons.lock,
            title: 'Change Password',
            onTap: () {
              Navigator.pushNamed(context, '/update_password');
            },
          ),

          const SizedBox(height: 30),

          Text(
            'App Settings',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.blueText,
            ),
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.brightness_6,
            title: 'Theme',
            onTap: () {
              Navigator.pushNamed(context, '/theme_settings');
            },
          ),

          const SizedBox(height: 30),

          if (role != 'admin')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blueText,
                  ),
                ),
                const SizedBox(height: 10),
                _buildSettingsTile(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () {
                    Navigator.pushNamed(context, '/help_center');
                  },
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'About App',
                  onTap: () {
                    Navigator.pushNamed(context, '/about_app');
                  },
                ),
              ],
            ),

          const SizedBox(height: 20),

          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: 'Log Out',
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.blueText),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: AppColors.blueText,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
