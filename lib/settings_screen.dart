import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  final bool isAdmin; 

  const SettingsScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Account',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context, 
            icon: Icons.person, 
            title: 'Update Username', 
            onTap: () {
              Navigator.pushNamed(context, '/update_username'); // <-- Navigate to Update Username
            }
          ),
          _buildSettingsTile(
            context, 
            icon: Icons.email, 
            title: 'Update Email', 
            onTap: () {
              Navigator.pushNamed(context, '/update_email'); // <-- Navigate to Update Email
            }
          ),
          _buildSettingsTile(
            context, 
            icon: Icons.lock, 
            title: 'Change Password', 
            onTap: () {
              Navigator.pushNamed(context, '/update_password'); // <-- Navigate to Update Password
            }
          ),

          const SizedBox(height: 30),

          Text(
            'App Settings',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context, 
            icon: Icons.notifications, 
            title: 'Notifications', 
            onTap: () {
              // Notifications - feature not added yet
            }
          ),
          _buildSettingsTile(
            context, 
            icon: Icons.brightness_6, 
            title: 'Theme', 
            onTap: () {
              Navigator.pushNamed(context, '/theme_settings'); // << Theme Settings
            }
          ),

          const SizedBox(height: 30),

          if (isAdmin)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Tools',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 10),
                _buildSettingsTile(
                  context,
                  icon: Icons.manage_accounts,
                  title: 'Manage Users',
                  onTap: () {
                    Navigator.pushNamed(context, '/admin_pin'); // <-- Manage Users flow
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),

          Text(
            'Support',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context, 
            icon: Icons.help_outline, 
            title: 'Help Center', 
            onTap: () {
              Navigator.pushNamed(context, '/help_center'); // << Help Center
            }
          ),
          _buildSettingsTile(
            context, 
            icon: Icons.info_outline, 
            title: 'About App', 
            onTap: () {
              Navigator.pushNamed(context, '/about_app'); // <-- About App
            }
          ),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: 'Log Out',
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false); // Logout
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.teal,
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
